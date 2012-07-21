#!/usr/bin/env ruby
# coding: utf-8
#Author: Roy L Zuo (roylzuo at gmail dot com)
#Description: 

require 'ohm'
require 'set'

module Ohm
  # Provides created_at / updated_at timestamps.
  #
  # @example
  #
  # class Post < Ohm::Model
  # include Ohm::Timestamping
  # end
  #
  # post = Post.create
  # post.created_at.to_s == Time.now.utc.to_s
  # # => true
  #
  # post = Post[post.id]
  # post.save
  # post.updated_at.to_s == Time.now.utc.to_s
  # # => true
  module LoboTimestamp
    def self.included(model)
      model.attribute :created_at
      model.attribute :updated_at
    end

    def save!
      self.created_at = Time.now.utc.to_i if new?
      self.updated_at = Time.now.utc.to_i

      super
    end
  end

  class PlainSet < ::Set
    def each
      to_a.each {|i| yield i}
    end

    def key
      @key
    end

    def db
      @db
    end

    # get all data in one go with SMEMBERS
    def to_a
      db.smembers(key)
    end

    # add a member with SADD
    def add(o)
      db.sadd(key, o.to_s)
    end
    alias_method :<<, :add

    # remove a member with SREM
    def delete(item)
      db.srem(key, item.to_s)
    end

    # query existence of member with SISMEMBER
    def include?(item)
      db.sismember(key, item.to_s)
    end

    def initialize(key, db)
      @key = key
      @db = db
    end
  end

  # make attributes expirable
  #
  module ExpiringKey
    def self.included(base)
      base.include InstanceMethods
      base.extend ClassMethods
    end

    module InstanceMethods
    end

    module ClassMethods
      def expire(attr, ttl)
        @@expire ||= {}
        attr = attr.to_sym
        @@expire[attr] = ttl.to_i
        index   attr
      end

      def create(*args)
        object = super(*args)
        if !object.new? and not @@expire.empty?
          @@expire.each do |attr, ttl|
            Ohm.redis.expire(object.key[attr], ttl)
          end
          #Ohm.redis.expire("#{object.key}:_indices", @@expire)
        end
        object
      end
    end
  end

  # add ability to show models created within a number of seconds
  #
  #   to use this module, remember to add 
  #
  #     add_to_latest         to  after_create
  #     remove_from_latest    to  after_delete
  #
  module LoboLatest
    def self.included(base)
      base.extend ClassMethods
      # add to following lines to model to make :latest work!
      #   DOES NOT WORK with Ohm 1.0+
      #base.class_eval {
        #after :create , :add_to_latest
        #after :destroy, :remove_from_latest
      #}
    end

    protected

    def add_to_latest
      self.class.key[:latest].zadd(created_at, id)
    end

    def remove_from_latest
      self.class.key[:latest].zrem(id)
    end

    module ClassMethods
      # get instances within a period
      def latest
        key[:latest].zrevrange(0,-1).map(&self)
      end

      def latest_within(seconds, timeout = 300)
        k = "latest_#{seconds}".to_sym
        unless key[k].exists
          zk = ('z_' + k.to_s).to_sym
          key[zk].zunionstore([key[:latest]])
          key[zk].zremrangebyscore(0,Time.now.to_i - seconds)
          key[zk].expire(timeout)   # in 5 minutes by default
          # some how adding an array directly to a set does not work here we add
          # one by one in a single transaction
          #db.sadd(key[k], key[zk].zrevrange(0, -1))
          ids = key[zk].zrevrange(0, -1)
          db.multi do
            ids.each { |id| key[k].sadd id }
          end
          key[k].expire(timeout)    # in 5 minutes by default
        end
        Set.new(key[k], key, self)
      end
    end
  end

  class MultiSet
    # add a #save method to MultiSet so that values can be stored for
    # future use
    def save(save_key)
      execute{|k| db.sinterstore(save_key, k)}
      Set.new(save_key, namespace, model)
    end
  end

  class Model
    # a shortcut for 
    #   
    #   User.with(:name, 'filter')
    #
    # when there is only one key
    #
    #   User.find(filter).first
    #
    # when there are multiple keys
    #
    # return nil when not found or exceptions raised on none unique field
    #
    def self.first(hash)
      if hash.size == 1
        with(hash.keys.first, hash.values.first)
      else
        all.find(hash).first
      end
    rescue
      nil
    end

    def self.plain_set(name)
      define_method name do
        Ohm::PlainSet.new(self.key[name], self.db)
      end
    end
  end
end

def convert_base(dec, base)
  nums ='0123456789ABCDEFGHI'\
        'JKLMNOPQRSTUVWXYZab'\
        'cdefghijklmnopqrstuvwxyz+/'
  #allows up to base 64
  #add your own symbols to allow you to use higher bases
  result = ""
  #result string
   
  return nil if dec.instance_of? Float
  #if anyone has any idea how to make floating points acceptable, I'd love to hear it!
   
  return nil if base < 2
  #base 0 isn't possible, and neither is base 1
   
  return 0 if dec == 0

  #0 is 0 in every base
  while dec != 0
    result += nums[dec%base].chr
    dec /= base
  end
  return result.reverse    
end

# Return a relative time description in Chinese
#
def relative_time(start_time)
  start_time = start_time.to_i
  diff_seconds = Time.now.to_i - start_time
  case diff_seconds
    when 0 .. 10
      "数秒钟前"
    when 11 .. 59
      "#{diff_seconds.to_i}秒前"
    when 60 .. (3600-1)
      "#{diff_seconds/60}分钟前"
    when 3600 .. (3600*24-1)
      "#{diff_seconds/3600}小时前"
    when (3600*24) .. (3600*24*30) 
      "#{diff_seconds/(3600*24)}天前"
    else
      Time.at(start_time).strftime("%Y年%m月%d日")
  end
end

