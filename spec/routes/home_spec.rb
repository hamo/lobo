#!/usr/bin/env ruby
# encoding: UTF-8
require "spec_helper"

describe '主页', :type => :request do
  it "应该有正确的标题" do 
    get "/"
    response.should have_selector("title", :content => '嘟噜')
  end

  it '应该有content区域' do
    post1 = Fabricate(:post)
    get '/'
    response.should have_selector("#content") do |div|
      div.should have_selector("a", :content => post1.title)
    end
  end

end
