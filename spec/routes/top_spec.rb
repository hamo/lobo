#!/usr/bin/env ruby
# coding: utf-8
require "spec_helper"

describe '分数最高' do
  it '应该有正确的标题' do
    get "/top"
    response.should have_selector("title", :content => '分数最高')
  end

  it '应该把文章按karma排序' do
    p1 = Fabricate(:post)
    p2 = Fabricate(:post)
    p3 = Fabricate(:post)
    u1 = Fabricate(:user)
    u2 = Fabricate(:user)
    u3 = Fabricate(:user)
    u1.upvote(p3)
    u2.upvote(p3)
    u3.upvote(p3)
    u2.upvote(p2)
    u3.upvote(p2)
    u3.upvote(p1)
    get '/top'
    response.should have_selector("div.link") do |link|
      link.first.should have_selector("div.rank", :content => '1')
      link.first.should have_selector("span.karma", :content => '4')
      link.last.should have_selector("div.rank", :content => '3')
      link.last.should have_selector("span.karma", :content => '2')
    end
  end

  it '新帖子应该在 /latest 排在第一' do
    5.times do 
      Fabricate(:post)
    end
    sleep 1
    po = Fabricate(:post)
    get '/latest'
    response.should have_selector("div.link") do |link|
      link.first.should have_selector("div.rank", :content => '1')
      link.first.should have_selector("a.trackable", :content => po.title)
    end
  end
end
