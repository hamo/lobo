#!/usr/bin/env ruby
# coding: utf-8
#Description: 
require 'spec_helper'

describe "User actions" do
  describe '举报' do
    before :each do 
      @po = Fabricate(:post)
      @po1 = Fabricate(:post)
      @u = Fabricate(:user)
      @admin = Fabricate(:user)
      @admin.tags << 'can_sanction'
    end

    it 'post karma < 10不能举报' do
      @u.should_not be_able_to_report
    end

    it 'post karma >= 10可以举报' do
      10.times { Fabricate(:post, :author => @u) }
      @u.should be_able_to_report
    end

    it 'Post#reported_by应该可以显示举报人' do
      10.times { Fabricate(:post, :author => @u) }
      @po.reported_by.should be_nil
      @u.report(@po).should_not be_nil
      @po.reported_by.should_not be_nil
    end

    it '一个帖子只能举报一次' do
      u = Fabricate(:user)
      10.times { Fabricate(:post, :author => u) }
      10.times { Fabricate(:post, :author => @u) }
      @u.report(@po).should be_true
      u.report(@po).should be_false
    end

    it '没被举报的帖子不能被review' do
      10.times { Fabricate(:post, :author => @u) }
      po = Fabricate(:post)
      @u.report(@po)
      @admin.review(@po, true).should_not be_nil
      @admin.review(po, true).should be_nil
    end

    it 'review通过的帖子不扣分，没通过的扣50分' do
      10.times { Fabricate(:post, :author => @u) }
      @u.report(@po1)
      @admin.review(@po1, true)
      @po1.karma.should == 1
      @u.report(@po)
      @admin.review(@po, false)
      @po.karma.should == -49
    end

    it 'review通过，举报不通过，节操-5' do
      10.times { Fabricate(:post, :author => @u) }
      @u.report(@po1)
      lambda do 
        @admin.review(@po1, true)
      end.should change(@u, :conduct_karma).by(-5)
    end

    it 'review后，举报通过，节操+5' do
      10.times { Fabricate(:post, :author => @u) }
      @u.report(@po)
      lambda do 
        @admin.review(@po, false)
      end.should change(@u, :conduct_karma).by(5)
    end
  end

  describe '订阅' do
    before :each do
      @u = Fabricate(:user)
      @pc = Fabricate(:private_category)
      @pm = Fabricate(:user)
      @pc.add_admin @pm
    end

    it '私密圈子管理员批准后能加入' do
      @pc.add_pending_subscriber @u
      @u.subscriptions.should_not include(@pc)
      subs = @pm.moderated_categories.to_a.collect{|c|
        Subscription.find(:category_id => c.id).to_a
      }.flatten.first
      subs.should_not be_nil
      subs.user.should == @u
      @pc.accept_pending_subscriber @u
      @u.subscriptions.should include(@pc)
    end
  end
end