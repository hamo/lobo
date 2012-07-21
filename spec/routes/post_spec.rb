#!/usr/bin/env ruby
# coding: utf-8
require "spec_helper"

describe 'post' do

  it '应该有正确的标题' do
    post = Fabricate(:post)
    get "/p/#{post.hash}"
    response.should have_selector("title", :content => post.title)
  end

  it '应该可以正确显示浏览过的网页' do
    test_login
    po = Fabricate(:post)
    post "/session/add_history", :hash => po.hash
    visit '/'
    response.should have_selector("aside") do |div|
      div.should have_selector("a", :content => po.title)
    end
  end
  
  it '应该可以正确的发帖' do 
    lambda do
      test_login
      visit '/post/new'
      fill_in 'title', :with => 'blah blah ... blah'
      choose 'radio_url'
      fill_in 'url', :with => 'http://www.baidu.com'
      fill_in 'category', :with => '图片'
      click_button '发表'
    end.should change(Post.all, :size).by(1)
  end

  it '应该可以以json格式得到帖子' do
    po = Fabricate(:post)
    get "/post/get/#{po.hash}" 
    JSON.parse(body, :symbolize_names => true).should == po.to_hash.merge(:success => true)
  end

  it '应该可以删除帖子' do
    u = User.with(:name, 'roylez')
    po = Fabricate(:post, :author => u)
    lambda do
      test_login
      post "/post/delete/#{po.hash}"
    end.should change(Post.seek_public.find(:author_id => u.id), :size).by(-1)
  end
end
