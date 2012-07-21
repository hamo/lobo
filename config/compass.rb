#!/usr/bin/env ruby
# coding: utf-8
#Description: 

require 'bootstrap-sass'

if defined?(Sinatra)
  # This is the configuration to use when running within sinatra
  project_path = Sinatra::Application.root
  environment = :development
else
  # this is the configuration to use when running within the compass command line tool.
  css_dir = File.join 'public', 'stylesheets'
  relative_assets = true
  environment = :production
end

# This is common configuration
http_path = "/"
output_style = :compressed

# Directory containing the SASS source files
sass_dir = "app/views/css"
#
# Directory where Compass dumps the generated CSS files
css_dir = "public/stylesheets"
http_stylesheets_path = "/stylesheets"
#
# Directory where font files use in font-face declarations are stored
fonts_dir = "public/fonts"
#
# Directory where Compass stores the Grid image, and the sites images are
# stored
images_dir = "public/images"
http_images_path = "/images"
#
# Directory where the sites' JavaScript file are stored
javascripts_dir = "public/js"
