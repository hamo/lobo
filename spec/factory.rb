#!/usr/bin/env ruby
# coding: utf-8
#Description: 
require 'fabrication'
require 'faker'

Fabricator :user do
  name { sequence(:name) {|i| "dummy_#{i}"} }
  email { Faker::Internet.email }
  password "foobar"
  password_confirmation 'foobar'
  after_create {|user| user.save}
end

Fabricator :post do
  url {sequence(:url) {|i| "http://www.google.com/#{i}" }}
  title { Faker::Lorem.sentence }
  author! { Fabricate(:user) }
  category { Category[1] }
  after_create {|post| post.save }
end

Fabricator :content_post, :class_name => :post do
  title { Faker::Lorem.sentence }
  content { Faker::Lorem.paragraph }
  author! { Fabricate(:user) }
  category { Category[1] }
  after_create {|content_post| content_post.save }
end

Fabricator :comment do
  author! { Fabricate(:user) }
  parent! { Fabricate(:post) }
  content { Faker::Lorem.paragraph }
  after_create {|comment| comment.save }
end

Fabricator :category do
  name { sequence(:name) {|i| "fake_category_#{i}"}}
  rate          1
  privacy       0
  content_type  0
  after_create {|category| category.save}
end

Fabricator :private_category, :class_name => :category do
  name { sequence(:name) {|i| "pri_category_#{i}"}}
  rate          1
  privacy       2
  content_type  0
  after_create {|category| category.save }
end
