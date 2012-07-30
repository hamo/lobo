#!/usr/bin/env ruby
# coding: utf-8
#Description: 
require_relative 'shared'
require_relative 'sorting'

class Post < Ohm::Model
  include Ohm::LoboTimestamp
  include Ohm::Callbacks
  include Ohm::LoboLatest
  include Ohm::DataTypes

  attribute :url
  attribute :title
  attribute :content
  attribute :rendered_content

  reference :author  , :User
  reference :category, :Category
  reference :sanctioned_by , :User

  set :replies, :Comment

  counter :upvotes
  counter :downvotes
  counter :karma_modifier
  attribute :karma, Type::Integer
  index     :karma

  attribute :score, Type::Float
  index     :score
  attribute :controversy, Type::Float
  index     :controversy

  index   :domain

  plain_set :tags
  index     :available?

  def domain
    d = url ? url[/\/\/(?:www.)?([^\/]+)/i,1] : "self.#{category.display_name}"
    d.downcase
  end

  def reply_count
    count = replies.count
    replies.each do |reply|
      count += reply.reply_count  if reply.replies
    end
    count
  end

  def validate
    assert_present :author
    assert_present :title
    assert( "#{url}#{content}".size > 0 , [:post,:no_body])
    assert_present :category
    # should not allow non-subscribers to post to private category
    assert( (category.allow_posting? author) , [:category, :private_category])    if category
    # should not allow posting to a category that has mismatching content_type
    assert( category.type_allowed?(type), [:category, :type_not_allowed] )    if category
  end

  alias_method :hash, :id

  def id_hash
    "id_#{hash}"
  end

  def type
    url ? :url : :content
  end
  
  def has_content?
    content and rendered_content
  end

  def reported_by
    ar = Moderation.with(:post_id, id)
    ar ? ar.reporter : nil
  end

  def reviewed_by
    ar = Moderation.with(:post_id, id)
    ar ? ar.reviewer : nil
  end

  def to_hash
    {
      :hash => hash,
      :id_hash => id_hash,
      :karma => karma,
      :created_at => relative_time(created_at),
      :updated_at => relative_time(updated_at),
      :content => content,
      :url => url,
      :rendered_content => rendered_content,
    }
  end

  def update_score
    self.karma = upvotes - downvotes + karma_modifier
    self.score = post_hot_score(upvotes, downvotes, created_at)
    self.controversy = post_controversial_score(upvotes, downvotes, created_at)
    save
  end

  def deleted?
    tags.include?('deleted')
  end

  # The visibility of a post to users
  #
  # user => nil     can everyone see this post?
  # user => User    can a specific user see this post?
  #
  def visible?(user=nil)
    return false unless available?
    return false unless category.allow_viewing? user
    true
  end

  # Is the post still available (not deleted or hidden because of low karma)
  #
  def available?
    return false if deleted?
    return false if karma < app_settings(:post_karma_barrier)
    true
  end

  # all visible posts
  def self.seek_public
    all.except(:available? => false)
  end

  private 

  def after_create
    author_upvote
    # see LoboLatest
    add_to_latest
  end

  def after_delete
    # see LoboLatest
    remove_from_latest
  end
  
  def before_save
    category_fallback
    render_content
  end

  def author_upvote
    author.upvote(self)
  end

  def category_fallback
    self.category_id = Category.with(:name, 'uncategoried').id   unless category
  end

  def _initialize_id
    @id = convert_base(self.class.key[:id].incr.to_i + 100000, 62)
  end
  
  def render_content
    self.rendered_content = MARKDOWN.render(content.strip)    if content
  end

end
