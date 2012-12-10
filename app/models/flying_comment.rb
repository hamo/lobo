#!/usr/bin/env ruby
# coding: utf-8
#Description: 
#
#   Actions taken for posts, e.g. report, admin review, sanction, or even add to
#   favorate
require_relative 'shared'

class FlyingComment < Ohm::Model
  include Ohm::DataTypes

  attribute   :video_source
  attribute   :video_id

  attribute   :content

  def validate
    assert_present  :video_source
    assert_present  :video_id
  end

  private

  def _initialize_id
    @id = video_source.to_s + '_' + video_id.to_s
  end
end
