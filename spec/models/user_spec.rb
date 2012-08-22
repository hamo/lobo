#!/usr/bin/env ruby
# coding: utf-8
#Description: 
require 'spec_helper'

describe User do
  before :each do 
    @attr = { 
      :name => 'dummy_name',
      :email => 'sssss@gmail.com',
      :password => 'fooobra',
      :password_confirmation => 'fooobra',
    }
  end

  it '应该可以创建用户' do
    u = User.new(@attr)
    u.should be_valid
  end

  it '应该可以用正确的密码登录' do
    u = User.create(@attr)
    User.authenticate(@attr[:name],@attr[:password]).should == u
  end

  it '应该有:posts方法' do
    u = User.create(@attr)
    u.should respond_to(:posts)
  end

  it '应该拒绝过短的用户名' do
    u = User.new(@attr.merge(:name => 's'))
    u.should_not be_valid
  end

  it '应该允许中文名' do
    u = User.new(@attr.merge(:name => '么不是吧'))
    u.should be_valid
  end

  it '应该拒绝含有奇怪字符的用户' do
    u = User.new(@attr.merge(:name => 'dummy?'))
    u.should_not be_valid
  end

  describe '发帖子' do
    before(:each) do
      @user = User.create(@attr)
    end

    it ':posts应该包含用户所发的帖子' do
      l1 = Fabricate(:post, :author => @user)
      @user.posts.count.should == 1
    end

    it ':comments应包含用户所发的评论' do
      p1 = Fabricate(:post, :author => Fabricate(:user))
      c = Fabricate(:comment, :author => @user, :parent => p1)
      @user.comments.should include(c)
    end

    it '新帖子默认有1分' do
      u = Fabricate(:user)
      p1 = Fabricate(:post, :author => u)
      p1.karma.should == 1
      p1.upvotes.should == 1
      p1.downvotes.should == 0
      u.post_karma.should == 1
    end

    it '新评论也应该有1分' do
      u = Fabricate(:user)
      p1 = Fabricate(:post, :author => u)
      c = Fabricate(:comment, :author => u, :parent => p1)
      c.karma.should == 1
      u.comment_karma.should == 1
    end
  end

  describe '顶帖子' do
    before :each do
      @u1 = Fabricate(:user)
      @u2 = Fabricate(:user)
      @p = Fabricate(:post)
      @c = Fabricate(:comment)
    end

    it '应该可以将帖子顶起来' do
      @u1.upvote(@p)
      @u2.upvote(@p)
      @p.karma.should == 3
      @p.author.post_karma.should == 3
    end

    it '应该可以把评论顶起来' do
      @u1.upvote(@c)
      @u2.upvote(@c)
      @c.karma.should == 3
      @c.author.comment_karma.should == 3
    end

    it '应该可以把帖子埋下去' do
      @u1.downvote(@p)
      @u2.downvote(@p)
      @p.karma.should == -1
    end

    it '应该可以把评论埋下去' do
      @u1.downvote(@c)
      @u2.downvote(@c)
      @c.karma.should == -1
      @c.author.comment_karma.should == -1
    end

    it '应该可以重置voting' do
      @p.karma.should == 1
      @p.author.post_karma.should == 1
      @u1.downvote(@p)
      @u1.downvote(@p)
      @u1.downvote(@c)
      @u1.downvote(@c)
      @p.karma.should == 1
      @p.author.post_karma.should == 1
      @c.karma.should == 1
      @c.author.comment_karma.should == 1
    end

    it '应该可以flip voting' do
      @u1.downvote(@p)
      @u1.upvote(@p)
      @p.karma.should == 2
    end
  end

  describe '各种能力' do
    before(:each) do
      @u = User.create(@attr)
      @u1 = Fabricate(:user)
      @p = Fabricate(:post)
      @c = Fabricate(:comment)
    end

    it '应该有 tags 方法' do
      @u.should.respond_to? :tags
    end

    it '应该可以正确添加和删除tag' do
      @u.tags.add('与拉拉聊天')
      @u.tags.should include('与拉拉聊天')
      @u.tags.delete '与拉拉聊天'
      @u.tags.should_not include('与拉拉聊天')
    end

    it '应该可以砍还没砍过的文章' do
      lambda do
        @u.tags << 'can_sanction'
        @u.sanction(@p)
      end.should change(@p, :karma).by(-50)
      @p.author.post_karma.should == -49
    end

    it '应该不可以砍评论' do
      lambda do
        @u.tags << 'can_sanction'
        @u.sanction(@c)
      end.should change(@c, :karma).by(0)
    end

    it '应该不可以砍砍过的文章' do
      lambda do
        @u.tags << 'can_sanction'
        @u1.tags << 'can_sanction'
        @u.sanction(@p)
        @u1.sanction(@p)
      end.should change(@p, :karma).by(-50)
    end

    it '应该有subscriptions列表' do
      @u.should.respond_to? :subscriptions
    end

    it '应该可以订阅和退订类别' do
      @u.should.respond_to? :subscribe
      @u.should.respond_to? :unsubscribe
      c = Category.with(:name, 'pic')
      @u.subscribe c
      @u.subscriptions.to_a.should == [c]
      @u.unsubscribe c
      @u.subscriptions.to_a.should == []
    end

    it '订阅和退订应该正确的改变category的订阅人数' do
      c = Category.with(:name, 'pic')
      lambda do
        @u.subscribe c
      end.should change(c.subscribers, :size).by(1)
      lambda do
        @u.unsubscribe c
      end.should change(c.subscribers, :size).by(-1)
    end
  end
end
