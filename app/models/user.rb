#!/usr/bin/env ruby
# coding: utf-8
#Description: 
require_relative 'shared'
require 'digest'
require 'securerandom'

class User < Ohm::Model
  include Ohm::LoboTimestamp
  include Ohm::Callbacks

  attr_accessor :password, :password_confirmation
  attribute :name
  attribute :email
  attribute :salt
  attribute :password_digest

  unique :name
  index :email

  collection :posts   , :Post   , :author
  collection :comments, :Comment, :author

  set :post_upvotes     , :Post
  set :comment_upvotes  , :Comment
  set :post_downvotes   , :Post
  set :comment_downvotes, :Comment

  # subscribed categories
  set :subscriptions    , :Category

  counter :post_karma
  counter :comment_karma
  counter :conduct_karma

  plain_set :tags

  def validate
    assert_format :name, /\A[\w_.\u4e00-\u9fa5]{3,20}\Z/   if new?
    assert_unique :name
    assert_email :email unless email.to_s.empty?
    assert_present :password                  if new?
    assert_present :password_confirmation     if new?
    assert (password == password_confirmation), [:password, :not_equal]   if password
  end

  def self.authenticate(login, submitted_password)
    user = first(:name => login)
    ( user && user.has_correct_password?(submitted_password) ) ? user : nil
  end

  def self.authenticate_with_salt(id, cookie_salt)
    user = self[id]
    ( user && user.salt == cookie_salt ) ? user : nil
  end

  def has_correct_password?(submitted_password)
    password_digest == encrypt(submitted_password)
  end

  def change_password(pw, pw_confirm)
    self.password = pw
    self.password_confirmation = pw_confirm
    valid? ? save : nil
  end

  def change_email(email)
    self.email = email
    valid? ? save : nil
  end

  def upvote(item)
    vote(item, :up)
  end

  def downvote(item)
    vote(item, :down)
  end

  # vote something, up or down
  # If already voted and a same type of voting comes in, the vote will be reset.
  #
  # args: 
  #   item          a comment or post object
  #   type          :up / :down
  #
  def vote(item, type)
    # eg: post_upvotes
    item_class = item.class.to_s.downcase
    vote_collection = eval "#{item_class}_#{type}votes"
    
    author = item.author
    author_karma_sym = "#{item_class}_karma".to_sym  # :post_karma / :comment_karma

    # already voted? Then this vote will be reset back.
    if vote_collection.include? item
      db.multi do
        vote_collection.delete(item)
        case type
        when :up
          item.decr(:upvotes)
          author.decr(author_karma_sym)
        when :down
          item.decr(:downvotes)
          author.incr(author_karma_sym)
        end
      end
    else
      #make operations in an atomic fashion
      db.multi do

        # flipping vote?
        if eval("#{item_class}_upvotes").delete(item)
          item.decr(:upvotes)
          author.decr(author_karma_sym)
        end
        if eval("#{item_class}_downvotes").delete(item)
          item.decr(:downvotes)
          author.incr(author_karma_sym)
        end

        vote_collection.add item
        case type
        when :up
          item.incr(:upvotes)
          author.incr(author_karma_sym)
        when :down
          item.incr(:downvotes)
          author.decr(author_karma_sym)
        end
        #logger.debug "#{name} #{type}-voted #{item.class} #{item.hash}"

      end
    end
    item.update_score
  end

  # subscribe a category
  #
  def subscribe(category)
    c = (category.is_a?(Category) ? category : Category.first(:name => category.to_s))
    return nil unless c
    db.multi do
      self.subscriptions.add c
      c.subscribers.add self
    end
  end

  # unsubscribe a category
  #
  def unsubscribe(category)
    c = (category.is_a?(Category) ? category : Category.first(:name => category.to_s))
    return nil unless c
    db.multi do
      self.subscriptions.delete c
      c.subscribers.delete self
      c.delete_admin(self)
    end
  end

  def voted?(item)
    upvoted?(item) or downvoted?(item)
  end

  def upvoted?(item)
    vote_collection = eval "#{item.class.to_s.downcase}_upvotes"
    vote_collection.include? item
  end

  def downvoted?(item)
    vote_collection = eval "#{item.class.to_s.downcase}_downvotes"
    vote_collection.include? item
  end

  # check if user has an ability
  def tagged?(ab)
    tags.include? ab.to_s
  end

  # sanction a post
  def sanction(item)
    return if item.sanctioned_by or not item.is_a? Post
    return unless able_to_sanction?(item)
    author = item.author
    db.multi do
      item.sanctioned_by = self
      item.decr(:karma_modifier, 50)
      author.decr(:post_karma, 50)
    end
    item.update_score
  end

  def report(item, memo = nil)
    # cannot report unless post karma > 10 
    return false unless able_to_report?
    return false if item.reported_by
    rep = Moderation.new(:reporter => self, :post => item, :memo => memo)
    if rep.valid?
      rep.save
      true
    else
      false
    end
  end

  def review(post, approved = true)
    # reporter and viewer cannot be same person
    return if post.reported_by == self or post.reported_by.nil?
    # cannot review unless is a site admin or a category admin
    return unless able_to_review?(post)
    return if post.reviewed_by
    decision = approved ? 'positive' : 'negative'

    rev = Moderation.with(:post_id, post.id)
    rev.update(:reviewer => self, :result => decision)
    if approved
      post.reported_by.incr(:conduct_karma, -5)
    else
      sanction(post)
      post.reported_by.incr(:conduct_karma, 5)
    end

    rev
  end

  def able_to_sanction?(post = nil)
    unless post
      tagged?('can_sanction')
    else
      tagged?('can_sanction') || post.category.admins.include?(self)
    end
  end

  def able_to_report?
    post_karma >= 10
  end

  def able_to_review?(post)
    able_to_sanction?(post)
  end

  def moderated_categories
    tags.select{|i| i.start_with? '#'}.collect{|i| Category.with(:name, i[1..-1])}.compact
  end

  # creat a User:reset_#{id} to hold hash for password reset, expires in 60
  # minutes
  #
  # This field is *NOT* added as an Ohm attribute because Ohm caches attribute
  # values and this may cause discripencies between different instances, also
  # ohm does not handle ttl data nicely.
  #
  def create_password_reset_hash(ttl = 3600)
    hex = SecureRandom.hex
    reset_key = "User:reset_#{id}"
    db.setex(reset_key, ttl, hex)
    hex
  end

  # get password reset hash for current user
  def password_reset_hash
    db.get("User:reset_#{id}")
  end

  private

  def before_save
    encrypt_password    if password
  end

  def encrypt_password
    self.salt =  make_salt unless has_correct_password?(password)
    self.password_digest = encrypt(password)
  end

  def make_salt
    secure_hash("----#{password}--%---#{Time.now}")
  end

  def secure_hash(string)
    Digest::SHA2.hexdigest(string)
  end

  def encrypt(string)
    secure_hash("---#{salt}-----#{string}")
  end

  def _initialize_id
    @id = convert_base(self.class.key[:id].incr.to_i + 99, 62)
  end
end
