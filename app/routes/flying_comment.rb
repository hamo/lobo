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
      xml.i do
        fc.content.each do |msg|
          xml.d(msg['message'], :p => %w(stime mode size color date).map{|i| msg[i]}.join(",") )
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
    data['date'] = Time.now.to_i
    fc.content = (fc.content ? (fc.content << data) : [data])
    fc.save
  end

end
