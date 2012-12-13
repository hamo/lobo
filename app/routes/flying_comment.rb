#!/usr/bin/env ruby
# coding: utf-8
#Description: 

class Main
  
  # get flying comment for a video
  #
  get %r{/f/(\w+)_(\w+)} do |video_source, video_id|
    content_type 'text/xml'
    fc = FlyingComment[video_source + '_' + video_id]
    halt 404  unless fc
    user_name = logged_in? ? current_user.name : '匿名'
    nokogiri do |xml|
      xml.information do
        fc.content.each do |msg|
          xml.data do
            xml.playTime msg['playTime']
            xml.message(msg['message'], :fontsize => msg['fontsize'], :color => msg['color'], :mode => msg['mode'])
            xml.times msg['date']
            xml.user user_name
          end
        end
      end
    end
  end

  # send flying comment for a video
  #
  post %r{/f/(\w+)_(\w+)} do |video_source, video_id|
    fc = FlyingComment[video_source + '_' + video_id]
    halt 404  unless fc
    data = params.reject{|k, _| k == 'splat' || k == 'captures'}
    fc.content = (fc.content ? (fc.content << data) : [data])
    fc.save
  end

end
