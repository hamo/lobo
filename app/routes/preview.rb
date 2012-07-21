#!/usr/bin/env ruby
# coding: utf-8
#Description: 

class Main
  # preview a Post or a comment
  #
  # input JSON
  #   :content => hash of post or comment
  # output JSON
  #   :rendered_content => output ( if successful )
  #   :success => status
  #
  post '/preview' do
    return stamp_json(false) unless logged_in? 
    return stamp_json(false) unless params[:content]
    rendered_content = MARKDOWN.render(params[:content])
    return stamp_json(true, :rendered_content => rendered_content) 
  end
end

