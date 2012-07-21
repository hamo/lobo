#!/usr/bin/env ruby
# coding: utf-8
#Description: 
#
#   Actions taken for posts, e.g. report, admin review, sanction, or even add to
#   favorate
require_relative 'shared'

class Action < Ohm::Model
  include Ohm::LoboTimestamp

  reference   :user , :User
  reference   :post , :Post
  attribute   :action_type
  attribute   :action_result
  index       :user
  index       :post
  index       :action_type
  index       :action_result

  attribute   :memo

  def validate
    assert_present  :user
    assert_present  :post
    assert_present  :action_type
  end

end
