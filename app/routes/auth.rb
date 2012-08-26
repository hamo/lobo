#!/usr/bin/env ruby
# coding: utf-8
#Description: 
class Main

  get '/login' do
    redirect '/'    if logged_in?
    @title = '登录'
    haml :login
  end

  get '/register' do
    redirect '/'    if logged_in?
    @title = '注册新用户'
    haml :register
  end

  post '/login' do
    begin
      authenticate(params)
      session[:success] = '您已成功登录'
      redirect_back_or( back == '/login' ? '/' : back ) 
    rescue
      session[:error] = '用户名或密码错误'
      @title = '登录'
      haml :login
    end
  end

  post '/register' do
    if captcha_pass? or ENV['RACK_ENV'] == 'test'
      user = register(params) 
      if user.valid?
        user.save
        session[:user] = user.id
        redirect "/"
      else
        error_messages = parse_errors(user.errors) do |e|
          case e
          when [:name                 , :not_unique] ; '用户名已经存在'
          when [:name                 , :not_present]; '您见过没名字的用户么？'
          when [:name                 , :format]     ; '好歹取个5个英文字母以上长度的名字吧'
          when [:email                , :not_email]  ; '邮件格式不对哦亲'
          when [:password             , :not_present]; '这里不是银行，但是还是要密码滴～～'
          when [:password_confirmation, :not_present]; '智能反机器人程序要求您再确认下密码'
          when [:password             , :not_equal]  ; '细心点咯，两次密码不一样呢'
          end
        end.join('<br/>')
        session[:error] = error_messages
      end
    else
      session[:error] = '图形验证未通过'
    end
    @title = '注册新用户'
    haml :register
  end

  get '/logout' do
    session.clear
    redirect '/'
  end

  get '/reset_password' do
    haml :reset_password_request
  end

  get '/reset_password/:user_id/:reset_hash' do
    u = User[params[:user_id]]
    halt 404 unless u and u.password_reset_hash == params[:reset_hash]
    haml :reset_password
  end

  post '/reset_password/:user_id/:reset_hash' do
    u = User[params[:user_id]]
    halt 404 unless u and u.password_reset_hash == params[:reset_hash]
    if u.change_password(params[:password], params[:password_confirmation])
      session[:info] = '您的密码已更改，请重新登录'
      redirect '/login'
    else
      session[:error] = parse_errors(u.errors) do |e|
        case e
        when [:password             , :not_present]; '这里不是银行，但是还是要密码滴～～'
        when [:password_confirmation, :not_present]; '智能反机器人程序要求您再确认下密码'
        when [:password             , :not_equal]  ; '细心点咯，两次密码不一样呢'
        end
      end
      redirect current_path
    end
  end

  post '/reset_password' do
    u = User.with(:name, params[:name])
    # record matches, send out an email
    if u and u.email == params[:email]
      # generate a url to reset password
      url = password_reset_url(u)
      
      # sends out an email
      email = Mail.new do
        from        "admin@#{app_settings(:domain)}"
        to          u.email
        subject     "密码重置链接"
        body        %Q{
          您好,

            您在#{app_settings(:domain)}提交的密码重置请求已经被受理，请点击下面的链接来设置一个新密码：

              #{url}
          
            谢谢！
        }
      end

      email.deliver
      session[:info] = '一封含有重置密码的链接的电子邮件已经发出，请您注意查收'
    else
      session[:error] = '用户不存在或注册邮箱不匹配，请确认后再重试'
    end
    redirect_back_or( back == '/login' ? '/' : back ) 
  end
end
