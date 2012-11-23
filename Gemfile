if RUBY_VERSION =~ /1.9/
  Encoding.default_external = Encoding::UTF_8
  #Encoding.default_internal = Encoding::UTF_8
end

source "http://ruby.taobao.org"

gem 'bundler'

gem 'monk-glue'            , :ref => '8a59f', :require => 'monk/glue', :git => 'git://github.com/monkrb/glue.git'
gem 'ohm'                  , '1.2.0'
gem "hiredis"              , "0.4.5"
gem 'redis'                , '3.0.2', :require => ["redis/connection/hiredis", "redis"]
gem 'ohm-contrib'          , '1.2.0', :require => 'ohm/contrib'
#gem 'maruku'               , '0.6.0'
gem 'rack'                 , '1.4.1'
gem 'rack-protection'      , '1.2'

# redis-search related
gem 'chinese_pinyin'
gem 'rmmseg-cpp-huacnlee'
gem 'redis-namespace'
gem 'redis-search'         , :ref => 'c21e1', :git => 'git://github.com/roylez/redis-search.git'

# compass must be loaded before sinatra!!!
gem 'compass'
gem 'bootstrap-sass'       , '~> 2.2.1.1'

gem 'pagination'           , :ref => 'c1193', :git => 'git://github.com/roylez/pagination.git'

gem 'redcarpet'
gem 'pygments.rb'

gem 'haml'                 , '3.1.7'
gem 'sass'                 , '3.2.3', :require => 'sass/plugin'

gem 'sinatra'              , '1.3.3', :require => 'sinatra/base'
gem 'sinatra-static-assets', '1.0.4', :require => 'sinatra/static_assets'
gem 'thin'

gem 'rake'

gem 'mail'                 , '2.4.4'

group :production do
  # newrelic.yml need to be put in "config" subdirectory
  gem 'newrelic_rpm'
  gem "unicorn", "~> 4.4.0"
end

group :development do
  gem 'pry'
  gem 'fabrication', '1.3.1'
  gem 'faker', '0.3.1'
  gem 'sprite-factory'
  gem 'rb-inotify', :require => false
  gem 'guard-rspec'
  gem 'guard-livereload'
  gem 'rack-livereload'
  gem 'guard-compass'
  gem 'guard-coffeescript'
  gem 'therubyracer'
end

group :test do
  gem 'faker'    , '0.3.1'
  gem 'fabrication', '1.3.1'
  gem 'rack-test', '0.6.2', :require => 'rack/test'
  gem 'webrat'   , '0.7.3'
  gem 'rspec'    , '2.10.0'
  gem 'spork'
end
