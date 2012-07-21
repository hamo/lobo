#!/usr/bin/env ruby
# coding: utf-8
#Description: 
require 'spec_helper'

describe Category do
  before(:each) do
    @attr = { :name => 'lol', :display_name => '得意的笑', :rate => 4, :privacy => 0, :content_type => 0}
  end

  it '应该可以成功创建分类' do
    c = Category.new(@attr)
    c.should be_valid
  end

  it '应该拒绝不合理的分类名' do
    Category.new(@attr.merge(:name => '你好')).should_not be_valid
  end

  it '应该将默认display name设为name' do
    c = Category.create(@attr.merge(:display_name => nil))
    c.display_name.should == c.name
  end

  it '新帖子应该能够在对应分类里出现' do
    c = Category.with(:name, 'pic')
    lambda do
      po = Post.create( :title => 'blahblah', :url => 'http://google.com', :author => User.all.first, :category => c)
    end.should change(c.posts, :size).by(1)
  end

  it '存盘的时候应该自动渲染成markdown' do
    c = Category.create(@attr.merge(:note => '**这是描述**', :sidebar => '**这是侧边栏**'))
    c.rendered_note.should have_selector('strong')
    c.rendered_sidebar.should have_selector('strong')
  end

  it '应该包含管理员相关的属性和方法' do
    c = Category.create(@attr)
    c.should.respond_to? :admins
    c.should.respond_to? :add_admin
    c.should.respond_to? :delete_admin
  end

  it '应该可以添加删除分类管理员' do
    c = Category.create(@attr)
    u = Fabricate(:user)
    c.add_admin u
    c.admins.should include(u)
    c.delete_admin u
    c.admins.should_not include(u)
  end

  it '应该拒绝发类型不匹配的帖子' do
    c = Category.create(@attr.merge(:content_type => 1))
    po1 = Fabricate(:post, :category => c)
    po2 = Fabricate(:content_post, :category =>c)
    po1.should be_valid
    po2.should_not be_valid
  end

  it '应该可以创建私有分类' do
    c = Category.create(@attr.merge(:privacy => 1))
    c.should be_valid
    c.privacy.should == 1
  end

  it '只有订阅人才能发帖到完全私有分类' do
    c = Category.create(@attr.merge(:privacy => 2))
    po = Post.create( :title => 'blahblah', :url => 'http://google.com', :author => User.all.first, :category => c)
    po.should be_nil
  end

  it '私有分类的帖子应该只有订阅人才能看到' do 
    c = Category.create(@attr.merge(:privacy => 2))
    u1 = User.all.to_a.first
    u2 = Fabricate(:user)
    u1.subscribe c
    po = Post.create( :title => 'blahblah', :url => 'http://google.com', :author => u1, :category => c)
    po.should be_valid
    po.should be_visible(u1)
    po.should_not be_visible(u2)
  end
end
