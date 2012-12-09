# This file contains the bootstraping code for a Monk application.
RACK_ENV = ENV["RACK_ENV"] ||= "development" unless defined? RACK_ENV
ROOT_DIR = $0 unless defined? ROOT_DIR

# Helper method for file references.
#
# @param args [Array] Path components relative to ROOT_DIR.
# @example Referencing a file in config called settings.yml:
#   root_path("config", "settings.yml")
def root_path(*args)
  File.join(ROOT_DIR, *args)
end

require "sinatra/base"

class Glue < Sinatra::Base
  set :dump_errors, true
  set :logging, true
  set :methodoverride, true
  set :raise_errors, Proc.new { test? }
  set :root, root_path
  set :run, Proc.new { $0 == app_file }
  set :show_exceptions, Proc.new { development? }
  set :static, true
  set :views, root_path("app", "views")

  configure :development do
    require_relative "glue_reloader"

    use Glue::Reloader
  end

  configure :development, :test do
    begin
      require "ruby-debug"
    rescue LoadError
    end
  end
end

#====================logging helper=============
require 'logger'

def logger
  $logger ||= begin
    $logger = ::Logger.new(root_path("log", "#{RACK_ENV}.log"))
    $logger.level = ::Logger.const_get((monk_settings(:log_level) || :warn).to_s.upcase)
    $logger.datetime_format = "%Y-%m-%d %H:%M:%S"
    $logger
  end
end

#=========settings helper=======================
require 'yaml'

def monk_settings(key)
  $monk_settings ||= YAML.load_file(root_path("config", "settings.yml"))[RACK_ENV.to_sym]

  unless $monk_settings.include?(key)
    message = "No setting defined for #{key.inspect}."
    defined?(logger) ? logger.warn(message) : $stderr.puts(message)
  end

  $monk_settings[key]
end

