# -*- coding: utf-8 -*-
require 'open-uri'

module LoboHelpers

    def captcha_pass?
      session = params[:captcha_session].to_i
      answer  = params[:captcha_answer].gsub(/\W/, '')
      #open("http://captchator.com/captcha/check_answer/#{session}/#{answer}").read.to_i.nonzero? rescue false
      open("http://www.opencaptcha.com/validate.php?img=#{session}&ans=#{answer}").read == 'pass' rescue false
    end

    def captcha_session
      @captcha_session ||= rand(9000) + 1000
    end

    def captcha_answer_tag
      "<input id=\"captcha-answer\" name=\"captcha_answer\" type=\"text\" size=\"10\"/>"
    end

    def captcha_image_tag
      "<input name=\"captcha_session\" type=\"hidden\" value=\"#{captcha_session}\"/>\n" +
      #"<a href=\"javascript:void(0);\" onclick=\"change_captcha(event);\"><img id=\"captcha-image\" src=\"//captchator.com/captcha/image/#{captcha_session}\"/ title=\"点击更换验证码\"></a>"
      "<a href=\"javascript:void(0);\" onclick=\"change_captcha(event);\"><img id=\"captcha-image\" src=\"http://www.opencaptcha.com/img/#{captcha_session}.jpg\"/ title=\"点击更换验证码\"></a>"
    end

end
