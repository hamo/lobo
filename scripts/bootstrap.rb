#!/usr/bin/env ruby
# coding: utf-8
#Author: Roy L Zuo (roylzuo at gmail dot com)
#Description: 
load './init.rb'
#require './spec/factory'

def notice(msg)
  puts msg    unless ENV['RACK_ENV'] = 'test'
end

notice "创建缺省类别：uncategoried"
Category.create(:name => 'uncategoried', :display_name => '未分类', :rate => 2, :privacy => 0, :content_type => 0)

notice "创建初始类别：pic"
pic_sidebar = %Q{
这里是贴图版面，如果不清楚图片贴到哪个版面，可以发到这里。以下为版规：

* **禁止发网页链接**
* **禁止发成人图片**
* **上班不宜图片请发送到NSFW版面**
}
Category.create(:name => 'pic', :display_name => '图片', :rate => 3, :sidebar => pic_sidebar, :privacy => 0, :content_type => 0)

notice "创建初始类别：funny"
Category.create(:name => 'funny', :display_name => '趣味', :rate => 3, :privacy => 0, :content_type => 0)
