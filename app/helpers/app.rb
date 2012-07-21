#!/usr/bin/env ruby
# coding: utf-8
#Description: 
#
#  Application level helpers
#
class Main
  helpers Pagination::Helpers

  helpers do

    # Generate a <img> tag with dynamically selected logo file
    #
    def logo
      image_tag('images/logo.png', :id => 'logo', :alt => 'logo', :height => 40, :width => 40)
    end

    # Get a dynamic title based on @title variable
    #
    def title
      base_title = '萝卜'
      @title ? "#{base_title} | #{@title}" : base_title
    end

    # Return a relative time description in Chinese
    #
    def relative_time(start_time)
      start_time = start_time.to_i
      diff_seconds = Time.now.to_i - start_time
      case diff_seconds
        when 0 .. 10
          "数秒钟前"
        when 11 .. 59
          "#{diff_seconds.to_i}秒前"
        when 60 .. (3600-1)
          "#{diff_seconds/60}分钟前"
        when 3600 .. (3600*24-1)
          "#{diff_seconds/3600}小时前"
        when (3600*24) .. (3600*24*30) 
          "#{diff_seconds/(3600*24)}天前"
        else
          Time.at(start_time).strftime("%Y年%m月%d日")
      end
    end

    # get brand icons from setting mapping, item can be a Post or a Comment, or
    # perhaps a User
    def brand_icons(item)
      brands = send((item.class.to_s.downcase + '_brands').to_sym, item)
      brands.collect{|b| app_settings(:brand_icons)[b]}
    end

    # format time to a pretty chinese format
    #
    def pretty_format_time(seconds)
      t = Time.at(seconds.to_i)
      t.strftime("%Y年%m月%d日 %H点%M分")
    end

    # append status like :success => true to a hash object, and return a json
    # string
    #
    def stamp_json(status, hash = {})
      hash.merge(:success => status).to_json
    end

    # parse errors messages from validations
    #
    def parse_errors(error_hash)
      errors = error_hash.collect{|k, v|
        [ v.collect{|i| [k, i]} ]
      }.flatten(2)
      errors.collect{|e| yield e}
    end
  end
end
