#!/usr/bin/env ruby
# coding: utf-8
#Description: 

class Main
  
  # get flying comment for a video
  #
  get %r{/f/([^&]*)(&r=.*)?} do |cid, _|
    content_type 'text/xml'
    fc = FlyingComment[cid]
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
        end if fc.content
      end
    end
  end

  # send flying comment for a video
  #
  post '/f/:cid' do
    fc = FlyingComment[params[:cid]]
    halt 404  unless fc
    data = params.reject{|k, _| k == 'splat' || k == 'captures'}
    data['message'] = data['message'].chomp
    fc.content = (fc.content ? (fc.content << data) : [data])
    fc.save
  end

end
