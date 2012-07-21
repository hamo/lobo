#!/usr/bin/env ruby
# encoding: UTF-8
require "spec_helper"

describe '登录' do
  it '应该可以正确登录' do
    visit '/login'
    fill_in 'login_name', :with => 'roylez'
    fill_in 'login_password', :with => 'dummy'
    click_button '登录'
    last_response.should be_redirect
    follow_redirect!
    last_request.url.should == 'http://example.org/'
    response.should have_selector("title", :content => '主页')
  end

  it '应该拒绝错误的用户名' do
    visit '/login'
    fill_in 'login_name', :with => 'roylez'
    fill_in 'login_password', :with => 'dummy1'
    click_button '登录'
    response.should have_selector("title", :content => '登录')
    response.should have_selector("div.alert")
  end

  describe '登录之后' do
    it '网站布局' do
      u = User.all.first
      get '/', {}, {'rack.session' => {"user" => u.id} }
      last_response.should have_selector("header") do |div|
        div.should have_selector("a", :content => '退出登录')
        div.should have_selector("a", :content => u.name)
      end
    end
  end

  it '应该可以正确的注册用户' do
    visit '/register'
    fill_in 'name'                 , :with => 'roylez1'
    fill_in 'password'             , :with => 'dummy1'
    fill_in 'password_confirmation', :with => 'dummy1'
    click_button '注册'
    last_response.should be_redirect
    follow_redirect!
    last_request.url.should == 'http://example.org/'
  end

  #it '应该拒绝不合法的用户名' do
    #visit '/register'
    #fill_in 'name'                 , :with => 'roy'
    #fill_in 'password'             , :with => 'dummy1'
    #fill_in 'password_confirmation', :with => 'dummy1'
    #click_button '注册'
    #response.should have_selector("title", :content => '注册')
  #end
end
