#!/usr/bin/env ruby
# coding: utf-8
#Description: 
#
#   Actions taken for posts, e.g. report, admin review, sanction, or even add to
#   favorate
require_relative 'shared'

class Subscription < Ohm::Model
  include Ohm::LoboTimestamp

  reference   :user     , :User
  reference   :category , :Category

  def validate
    assert_present  :user
    assert_present  :category
    # can only apply once
    assert( Subscription.find(:user_id => user_id, :category_id => category_id).size.zero? ,
           [:subscription, :application_pending]
          )
  end
end
