#!/usr/bin/env ruby
# coding: utf-8
#Description: 
#
#   Actions taken for posts, e.g. report, admin review, sanction, or even add to
#   favorate
require_relative 'shared'

class FlyingComment < Ohm::Model
  include Ohm::DataTypes

  reference   :post, Post

  attribute   :content, Type::Array

  def validate
    assert_present  :post_id
  end

  private

  def _initialize_id
    @id = post_id
  end
end
