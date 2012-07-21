#!/usr/bin/env ruby
# coding: utf-8
#Description: 

require "spec_helper"

describe '各种用户行为' do
  it '应该可以正确的渲染markdown' do
    test_login
    post '/preview', :content => '*hello*'
    res = JSON.parse(body, :symbolize_names => true)
    res[:success].should be_true
    res[:rendered_content].should have_selector(:em, :content => 'hello')
  end
end

describe "密码重置" do
  include Mail::Matchers

  before :each do
    Mail::TestMailer.deliveries.clear
    @u = Fabricate(:user)
  end

  it '应当可以发出密码重置邮件' do 
    visit '/reset_password'
    fill_in 'name', :with => @u.name
    fill_in 'email', :with => @u.email
    click_button 'reset_passwd_button'
    last_response.should be_redirect
    follow_redirect!

    should have_sent_email.to(@u.email)
  end

  it '密码重置链接应该有有效期' do
    post '/reset_password', :name => @u.name, :email => @u.email
    
    @u.class.db.get("User:reset_#{@u.id}").should_not be_nil
    @u.class.db.ttl("User:reset_#{@u.id}").should > 0
  end

  it '信息正确应当有发出邮件的提示' do
    visit '/reset_password'
    fill_in 'name', :with => @u.name
    fill_in 'email', :with => @u.email
    click_button 'reset_passwd_button'
    last_response.should be_redirect
    follow_redirect!

    last_response.should have_selector("div.alert-info")
  end

  it '信息不正确应当有错误提示' do
    visit '/reset_password'
    fill_in 'name', :with => @u.name + 'bug'
    fill_in 'email', :with => @u.email + 'here'
    click_button 'reset_passwd_button'
    last_response.should be_redirect
    follow_redirect!

    last_response.should have_selector("div.alert-error")
  end

  it '密码重置链接应该是好使的' do
    post '/reset_password', :name => @u.name, :email => @u.email
    url = "/reset_password/#{@u.id}/#{@u.class.db.get("User:reset_#{@u.id}")}"
    post url, :password => 'xxxxoxxx', :password_confirmation => 'xxxxoxxx'
    visit '/login'
    fill_in 'login_name', :with => @u.name
    fill_in 'login_password', :with => 'xxxxoxxx'
    click_button '登录'
    last_response.should be_redirect
    follow_redirect!
    last_request.url.should == 'http://example.org/'
    response.should have_selector("title", :content => '主页')
    last_response.should have_selector("header") do |div|
      div.should have_selector("a", :content => '退出登录')
      div.should have_selector("a", :content => @u.name)
    end
  end
end
