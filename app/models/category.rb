#!/usr/bin/env ruby
# coding: utf-8
#Author: Roy L Zuo (roylzuo at gmail dot com)
#Description: 
require_relative 'shared'

class Category < Ohm::Model
  include Ohm::LoboTimestamp
  include Ohm::Callbacks
  include Ohm::DataTypes

  collection :posts, :Post

  attribute :name
  attribute :display_name
  # description and community rules
  attribute :note
  attribute :rendered_note
  # rules on sidebar
  attribute :sidebar
  attribute :rendered_sidebar
  # category privacy control
  #     0 -> anyone can view and post
  #     1 -> anyone can view, only subscriber can post
  #     2 -> only subscriber can view and post
  attribute :privacy, Type::Integer
  # category content type control
  #   0 -> both url and content posts are allowed
  #   1 -> url only
  #   2 -> content only
  attribute :content_type, Type::Integer
  # how safe the contents in the category can be
  #   0 -> site wide announcements
  #   1 -> safe
  #   2 -> undefined/unknown
  #   3 -> NSFW contents
  #   4 -> NSFL
  attribute :rate, Type::Integer

  # category administrators
  set :admins    , :User

  # category subscribers
  set :subscribers, :User

  # user blacklist
  set :user_blacklist         , :User

  unique    :name
  unique    :display_name

  index     :allow_viewing?

  def validate
    assert_present :name
    assert_format :name        , /\A[\w_.]{2,30}\Z/
    assert((not ['random', 'all'].include? name), [:name, :reserved_name])
    assert_unique :name
    assert_unique :display_name  if not display_name.to_s.empty?
    assert_member :rate        , (0..4).to_a
    assert_member :privacy     , (0..2).to_a
    assert_member :content_type, (0..2).to_a
  end

  def add_admin(user)
    u = (user.is_a?(User) ? user : User.first(:name => user.to_s))
    return nil unless u
    self.admins.add u
    u.tags << "##{self.name}"
  end

  def delete_admin(user)
    u = (user.is_a?(User) ? user : User.first(:name => user.to_s))
    return nil unless u
    self.admins.delete u
    u.tags.delete "##{self.name}"
  end

  def allow_viewing?(user=nil)
    return false if user and self.user_blacklist.include?(user)
    if self.privacy == 0 || self.privacy == 1
      return true
    elsif user
      return user.subscriptions.include?(self)
    else
      return false
    end
  end

  def allow_posting?(user=nil)
    return false unless user
    return false if self.user_blacklist.include?(user)
    return self.privacy == 0 || user.subscriptions.include?(self)
  end

  def type_allowed?(post_or_type)
    allowed = case content_type
              when 0; [ :url, :content ]
              when 1; [ :url ]
              when 2; [:content]
              end
    case post_or_type
    when Post
      allowed.include? post_or_type.type
    when Symbol
      allowed.include? post_or_type
    else
      false
    end
  end

  def subscription_review_required?
    privacy == 2 || privacy == 1
  end

  def pending_subscribers
    Subscription.find(:category_id => self.id)
  end

  def add_pending_subscriber(user)
    return unless user
    subs = Subscription.new(:user => user, :category => self)
    subs.save   if subs.valid?
  end

  def accept_pending_subscriber(user)
    if subs = pending_subscribers.first(:user_id => user.id)
      subs.delete
      user.subscribe(self)
    end
  end

  def reject_pending_subscriber(user)
    if subs = pending_subscribers.first(:user_id => user.id)
      subs.delete
    end
  end

  def add_user_blacklist(user)
    self.user_blacklist.add user
  end

  def remove_user_blacklist(user)
    self.user_blacklist.delete user
  end

  def to_hash(opts = {})
    res = {
      :name => name,
      :display_name => display_name, 
      :created_at => relative_time(created_at),
      :updated_at => relative_time(updated_at),
      :note => note,
      :rendered_note => rendered_note,
      :sidebar => sidebar,
      :rendered_sidebar => rendered_sidebar,
      :privacy => privacy,
      :content_type => content_type,
      :rate => rate,
    }
    res.merge( :subscribers => subscribers.to_a.collect(&:id) ) if opts[:subscribers]
  end

  private
  
  def before_save
    set_fallback_display_name
    render_notes
  end
  
  def set_fallback_display_name
    self.display_name = name  if display_name.to_s.empty?
  end

  def render_notes
    self.rendered_note = MARKDOWN.render(note)  if note
    self.rendered_sidebar = MARKDOWN.render(sidebar) if sidebar
  end
end
