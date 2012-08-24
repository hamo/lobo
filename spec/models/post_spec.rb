#!/usr/bin/env ruby
# coding: utf-8
#Description: 
require 'spec_helper'

describe Post do
  before :each do
    @attr = { :url => 'http://www.google.com', 
              :title => 'Google dot come',
              :content => 'blah blah sfafaf blah',
              :category => Category[1]
            }
  end

  it '应该有:author方法' do
    l = Post.new(@attr)
    l.should respond_to(:author)
  end

  it '新帖子应该有hash' do
    l = Post.create(@attr.merge(:author => Fabricate(:user)))
    l.hash.should_not be_nil
  end

  it '应该能够正确的识别域名' do
    l = Post.new(@attr.merge(:url => 'http://www.google.com'))
    l.domain.should == 'google.com'
    l1 = Post.new(@attr.merge(:url => 'http://www.google.com/'))
    l1.domain.should == 'google.com'
    l2 = Post.new(@attr.merge(:url => 'http://google.com/'))
    l2.domain.should == 'google.com'
    l3 = Post.new(@attr.merge(:url => 'http://w3.google.com/'))
    l3.domain.should == 'w3.google.com'
  end

  it '新帖应该有默认的类别' do
    l = Post.create(@attr.merge(:author => Fabricate(:user)))
    l.category.should_not be_nil
  end

  it '被砍了之后应该知道是谁干的' do
    l = Post.create(@attr.merge(:author => Fabricate(:user)))
    l.should be_valid
    u = User.all.first
    u.add_tag 'can_sanction'
    u.sanction l
    l.sanctioned_by.should == u
  end
end
