class Main
  get "/css/:stylesheet.css" do
    content_type "text/css", :charset => "UTF-8"
    sass :"css/#{params[:stylesheet]}", Compass.sass_engine_options
  end

  get '/css/PIE.htc' do
    content_type 'text/x-component'
    send_file Sass::Plugin.options[:css_location] + '/PIE.htc'
    # open(Sass::Plugin.options[:css_location] + '/PIE.htc').read
  end
end
