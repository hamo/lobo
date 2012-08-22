if RUBY_VERSION =~ /1.9/
  Encoding.default_external = Encoding::UTF_8
  #Encoding.default_internal = Encoding::UTF_8
end

source "http://ruby.taobao.org"

gem 'bundler'

gem 'monk-glue'            , :ref => '8a59f', :require => 'monk/glue', :git => 'git://github.com/monkrb/glue.git'
gem 'ohm'                  , '1.1.1'
gem "hiredis"              , "0.4.5"
gem 'redis'                , '3.0.1', :require => ["redis/connection/hiredis", "redis"]
gem 'ohm-contrib'          , '1.1.0', :require => 'ohm/contrib'
gem 'maruku'               , '0.6.0'
gem 'rack'                 , '1.4.1'
gem 'rack-protection'      , '1.2'

# compass must be loaded before sinatra!!!
gem 'compass'
gem 'bootstrap-sass'

gem 'pagination'           , :ref => 'a0cb3', :git => 'git://github.com/roylez/pagination.git'

gem 'redcarpet'

gem 'haml'                 , '3.1.4'
gem 'sass'                 , '3.1.15', :require => 'sass/plugin'

gem 'sinatra'              , '1.3.3', :require => 'sinatra/base'
gem 'sinatra-static-assets', '1.0.2', :require => 'sinatra/static_assets'
gem 'thin'

gem 'rake'

gem 'mail'                 , '2.4.4'

group :production do
  gem "unicorn", "~> 4.3.1"
end

group :development do
  gem 'fabrication', '1.3.1'
  gem 'faker', '0.3.1'
  gem 'sprite-factory'
end

group :test do
  gem 'faker'    , '0.3.1'
  gem 'fabrication', '1.3.1'
  gem 'rack-test', '0.6.1', :require => 'rack/test'
  gem 'webrat'   , '0.7.3'
  gem 'rspec'    , '2.10.0'
  gem 'spork'
end
