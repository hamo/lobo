#!/usr/bin/env ruby
# coding: utf-8
#Description: 
require_relative 'shared'
require_relative 'sorting'

class Comment < Ohm::Model
  include Ohm::LoboTimestamp
  include Ohm::Callbacks
  include Ohm::LoboLatest
  include Ohm::DataTypes

  attribute :content
  attribute :rendered_content

  attribute :parent_hash

  reference :author       , :User
  reference :sanctioned_by, :User
  set       :replies      , :Comment

  attribute :ancestor_ids , Type::Array

  attribute :score, Type::Float
  index     :score
  attribute :karma, Type::Integer
  index     :karma

  counter :upvotes
  counter :downvotes
  counter :karma_modifier

  def parent=(post_or_comment)
    self.parent_hash = post_or_comment.hash
  end

  # Only comment hash contains '_'
  # see :hash_id for more details about comment hash
  def parent_is_post?
    not parent_hash.include?('_')
  end

  def parent
    parent_is_post? ? Post[parent_hash] : Comment[parent_hash]
  end

  # return an array of Post and Comment objects
  def ancestors
    nil unless ancestor_ids
    ancestor_ids.map{|id| id.include?('_') ? Comment[id] : Post[id] }
  end

  def post
    return @post if @post
    @post = Post[parent_hash.sub(/_.*$/,'')]
  end

  def reply_count
    count = replies.size
    replies.each do |reply|
      count += reply.reply_count
    end
    count
  end

  alias_method :hash, :id

  def id_hash
    "id_#{hash}"
  end

  def to_hash
    {
      :hash => hash,
      :id_hash => id_hash,
      :karma => karma,
      :created_at => relative_time(created_at),
      :updated_at => relative_time(updated_at),
      :content => content,
      :rendered_content => rendered_content,
    }
  end

  def update_score
    self.karma = upvotes - downvotes + karma_modifier
    self.score = comment_hot_score(upvotes, downvotes, created_at)
    save
  end

  private 

  def before_create
    store_ancestors
  end
  
  def after_create
    super
    author_upvote
    link_parent
    add_author_monitor
    notify_new_replies
  end

  # for each ancestor, notify its author that there is a new reply
  def notify_new_replies
    authors = ancestors.map(&:author).uniq
    authors.each { |au| au.increment_unread_replies(post) }
  end

  def before_save
    render_content
  end

  def add_author_monitor
    author.monitored_posts.add post
  end

  def render_content
    self.rendered_content = MARKDOWN.render(content)
  end

  def link_parent
    parent.replies.add self
  end

  def store_ancestors
    if parent.is_a? Comment and parent.ancestor_ids
      self.ancestor_ids = parent.ancestor_ids.unshift parent_hash
    else
      comm = self
      arr = []
      begin
        comm = comm.parent
        arr << comm.id
      end until comm.is_a? Post
      self.ancestor_ids = arr
    end
  end

  def author_upvote
    author.upvote(self)
  end

  def validate
    assert( "#{content}".size > 0 , [:comment,:no_content])
  end

  # comment hash is in this format 
  #
  #   <post_hash>_<base62(inc + 1000)>
  #
  def _initialize_id
    @id = parent_hash.sub(/_.*$/,'') + '_' + convert_base(self.class.key[:id].incr.to_i + 1000, 62)
  end
end
