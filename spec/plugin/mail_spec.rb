#!/usr/bin/env ruby
# coding: utf-8
#Description: 
#
require 'spec_helper'

describe "sending an email" do
  include Mail::Matchers

  before :each do
    Mail::TestMailer.deliveries.clear

    Mail.deliver do
      to ['mikel@me.com', 'mike2@me.com']
      from 'you@you.com'
      subject 'testing'
      body 'hello'
    end
  end

  it {should have_sent_email.from('you@you.com')}
end
