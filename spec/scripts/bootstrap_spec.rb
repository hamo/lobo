#!/usr/bin/env ruby
# coding: utf-8
#Author: Roy L Zuo (roylzuo at gmail dot com)
#Description: 
require 'spec_helper'

describe '初始化环境' do
  it '应该创建默认的类别' do
    Category.with(:name ,'uncategoried').should_not be_nil
    Category.with(:name ,'funny').should_not be_nil
    Category.with(:name ,'pic').should_not be_nil
    Category.with(:name ,'pic').display_name.should == '图片'
  end
end
