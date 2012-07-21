#!/usr/bin/env ruby
# coding: utf-8
require "spec_helper"

describe 'comment' do

  it '应该可以正确的发表评论' do 
    po = Fabricate(:post)
    lambda do
      test_login
      visit "/p/#{po.hash}"
      fill_in 'comment_content', :with => 'blah blah ... blah'
      click_button '发表回复'
    end.should change(po.replies, :size).by(1)
  end

end
