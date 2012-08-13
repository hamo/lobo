#!/usr/bin/env ruby
# coding: utf-8
#Description: 
#
#   Actions taken for posts, e.g. report, admin review, sanction, or even add to
#   favorate
require_relative 'shared'

class Moderation < Ohm::Model
  include Ohm::LoboTimestamp

  reference   :reporter , :User
  reference   :reviewer , :User
  reference   :post     , :Post

  unique      :post_id

  attribute   :result
  index       :result

  attribute   :memo

  def validate
    assert_present  :reporter
    assert_unique   :post_id    if new?
    assert_present  :post
  end
end
