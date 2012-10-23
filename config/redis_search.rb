#!/usr/bin/env ruby
# coding: utf-8
#Description: 
require "redis"
require "redis-namespace"
require 'redis-search'

#require "redis-search"

# don't forget change namespace
search_db = Redis.new(:host => monk_settings(:redis)[:host],:port => monk_settings(:redis)[:port], :db => monk_settings(:search_db))

# Give a special namespace as prefix for Redis key, when your have more than one project used redis-search, this config will make them work fine.
SEARH_DB = Redis::Namespace.new(app_settings(:domain), :redis => search_db)

Redis::Search.configure do |config|
  config.redis = SEARH_DB
  config.complete_max_length = 100
  config.pinyin_match = true
  # use rmmseg, true to disable it, it can save memroy
  config.disable_rmmseg = false
end
