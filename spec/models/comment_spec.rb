#!/usr/bin/env ruby
# coding: utf-8
#Description: 
require 'spec_helper'

describe Comment do
  before(:each) do
    @user = Fabricate(:user)
    @post = Fabricate(:post, :author => @user)
    @c = Fabricate(:comment, :author => @user, :parent => @post)
  end

  it '应该可以查到原始帖子' do
    @c.post.should_not be_nil
  end

  it '应该可以查到是回的哪个帖' do
    lambda do
      u = Fabricate(:user)
      c1 = Fabricate(:comment, :author => u, :parent => @post)
      @c.replies.add c1
    end.should change(@c.replies, :count).by(1)
  end

  it '新评论应该有hash' do
    c = Comment.create(:content => 'some dummy text', :author => @user, :parent => @post)
    c.hash.should_not be_nil
  end

  it '新评论hash应该包含原始post的hash' do
    c = Comment.create(:content => 'some dummy text', :author => @user, :parent => @c)
    c.post.should == @post
    c.hash.should =~ /#{@post.hash}_\w+/
  end

  it '存盘的时候应该自动渲染成markdown' do
    c = Comment.create(:content => 'some **dummy** text', :author => @user, :parent => @c)
    c.rendered_content.should have_selector('strong')
  end

end
