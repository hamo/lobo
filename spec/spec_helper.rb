#!/usr/bin/env ruby
#
# encoding: utf8

require 'rubygems'
require 'spork'
RACK_ENV = 'test'

Spork.prefork do

  require_relative '../init'
  require_relative 'factory'

  Mail.defaults do
    delivery_method :test
  end

  begin
    puts "Connected to Redis #{Ohm.redis.info["redis_version"]} on #{monk_settings(:redis)[:host]}:#{monk_settings(:redis)[:port]}, database #{monk_settings(:redis)[:db]}."

  rescue Errno::ECONNREFUSED
    puts <<-EOS

      Cannot connect to Redis.

      Make sure Redis is running on #{monk_settings(:redis)[:host]}:#{monk_settings(:redis)[:port]}.
      This testing suite connects to the database #{monk_settings(:redis)[:db]}.

      To start the server:
        env RACK_ENV=test monk redis start

      To stop the server:
        env RACK_ENV=test monk redis stop

    EOS
    exit 1
  end
end

Spork.each_run do
  # reload all ruby stuff
  Dir[root_path("app/**/*.rb")].each {|f| load f }
end

Webrat.configure {|config| config.mode = :rack }

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
  conf.include Webrat::Methods
  conf.include Webrat::Matchers # require for "should contain(...)"

  def app
    Main
  end

  def body
    last_response.body
  end

  def flush_db
    Ohm.flush # paranoia to prevent wiping out a prod database somehow
  end

  def create_default_user
    User.create(:name => 'roylez', :password => 'dummy', :password_confirmation => 'dummy', :email => 'roylzuo@gmail.com')
  end

  def test_login
    visit '/login'
    fill_in 'login_name', :with => 'roylez'
    fill_in 'login_password', :with => 'dummy'
    click_button 'login_button'
    follow_redirect!
  end

  conf.before(:each) do
    flush_db
    load "#{root_path('scripts/bootstrap.rb')}"

    create_default_user
  end

end
#Author: Roy L Zuo (roylzuo at gmail dot com)
#Author: Roy L Zuo (roylzuo at gmail dot com)
