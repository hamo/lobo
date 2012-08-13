#!/usr/bin/env ruby
# coding: utf-8
require "spec_helper"

describe 'category routing' do
  it '应该有正确的标题' do
    get "/l/uncategoried"
    response.should have_selector("title", :content => '未分类')
  end

  it '应该可以正确的创建新类别' do
    lambda do
      test_login
      visit '/category/new'
      fill_in 'display_name' , :with => '神马'
      fill_in 'name', :with => 'unicon'
      choose 'radio_rate3'
      fill_in 'note', :with => 'A flying horse in note'
      fill_in 'sidebar', :with => 'A jumping fox in sidebar'
      click_button '建立新类别'
    end.should change(Category.all, :size).by(1)
  end

  it '应该可以正确的创建新私有类别' do
    lambda do
      test_login
      visit '/category/new'
      fill_in 'display_name' , :with => '神马'
      fill_in 'name', :with => 'unicon'
      choose 'radio_rate3'
      choose 'radio_privacy1'
      fill_in 'note', :with => 'A flying horse in note'
      fill_in 'sidebar', :with => 'A jumping fox in sidebar'
      click_button '建立新类别'
    end.should change(Category.all, :size).by(1)
  end

  it '新建类别的管理员应该有创建人' do
    test_login
    visit '/category/new'
    fill_in 'display_name' , :with => '神马'
    fill_in 'name', :with => 'unicon'
    choose 'radio_rate3'
    choose 'radio_privacy1'
    fill_in 'note', :with => 'A flying horse in note'
    fill_in 'sidebar', :with => 'A jumping fox in sidebar'
    click_button '建立新类别'
    c = Category.first(:name => 'unicon')
    c.should_not be_nil
    c.admins.should include(User.first(:name => 'roylez'))
  end

  it '应该可以以json格式得到圈子' do
    ca = Fabricate(:category)
    get "/category/get/#{ca.name}" 
    #JSON.parse(body, :symbolize_names => true).should == ca.to_hash.merge(:success => true)
  end

  it '登录时应该可以以json格式得到圈子的订阅人' do
    ca = Fabricate(:category)
    test_login
    get "/category/get/#{ca.name}", :subscribers => '1' 
    #JSON.parse(body, :symbolize_names => true).should include?(:subscribers)
  end

end
