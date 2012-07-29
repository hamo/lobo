ROOT_DIR = File.expand_path(File.dirname(__FILE__)) unless defined? ROOT_DIR

ENV['TZ'] = 'Asia/Shanghai'

require "rubygems"
require 'json'
require 'bundler'

# to provide glued env and RACK_ENV var
RACK_ENV = ENV["RACK_ENV"] ||= "development" unless defined? RACK_ENV

Bundler.require(:default,RACK_ENV)
Bundler.setup(:default,RACK_ENV)

$logger = Logger.new(STDERR)

class Main < Monk::Glue
  register Sinatra::StaticAssets
  #make server more responsive
  #register Sinatra::Synchrony

  set :app_file, __FILE__
  #the following two are Sinatra defaults 
  set :public_folder, 'public'
  set :static, ENV["RACK_ENV"] != "production"

  configure do
    enable :logging, :dump_errors

    #set :haml, {:format => :html5, :escape_html => true}
    set :haml, {:format => :html5}
    set :scss, {:style => :compact, :debug_info => false}
    Compass.add_project_configuration(File.join(Main.root, 'config', 'compass.rb'))

    Sass::Plugin.options.merge(
      :template_location => 'app/views/css',
      :css_location => 'public/css'
    ) 
  end

  secret =
    begin
      File.read('config/secret.txt')
    rescue Errno::ENOENT
      random_secret = rand(10**128).to_s(36)
      puts <<-EOS
        Creating a random secret key for sessions

        For your Sinatra app to safely use sessions, a secret key
        must be used to prevent users from tampering with their
        cookie data (which could lead to unauthorized access to your
        application if you store login information in the session).

        The file config/secret.txt has been created with the following
        secret:

        #{random_secret}
        
      EOS
      File.open('config/secret.txt', 'w') do |out|
        out.write random_secret
      end
      random_secret
    end

  # enable session!!!
  use Rack::Session::Cookie, :secret => secret
  #use Rack::Session::Pool, :expire_after => 2592000    # server session
end

# Connect to redis database.
Ohm.connect(monk_settings(:redis))

# settings for the application
def app_settings(key)
  $app_settings ||= YAML.load_file(root_path("config", "app_settings.yml"))

  unless $app_settings.include?(key)
    message = "No setting defined for #{key.inspect}."
    defined?(logger) ? logger.warn(message) : $stderr.puts(message)
  end

  $app_settings[key]
end

# Load all application files.
Dir[root_path("app/**/*.rb")].each do |file|
  require file
end

# Load all configuration except compass
Dir[root_path("config/*.rb")].each do |file|
  require file  unless file =~ /compass/
end

if defined? Encoding
  Encoding.default_external = Encoding::UTF_8
end

Main.run! if Main.run?
