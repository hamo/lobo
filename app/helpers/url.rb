#!/usr/bin/env ruby
# coding: utf-8
#Description: 
require 'uri'

class Main
  helpers do

    def url_check(url)
      url_pattern = /\A(http|https):\/\/([a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}|(25[0-5]|2[0-4]\d|[0-1]?\d?\d)(\.(25[0-5]|2[0-4]\d|[0-1]?\d?\d)){3}|localhost)(:[0-9]{1,5})?(\/.*)?\z/ix
      return url.match(url_pattern)
    end
      
  end
end
