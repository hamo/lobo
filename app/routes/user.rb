#!/usr/bin/env ruby
# coding: utf-8

class Main
  get '/settings' do
    require_login
    @title = '用户设置'
    @header_nav = :user
    @user = current_user
    haml :'user/settings'
  end

  post '/settings' do
    halt 404 unless logged_in?
    u = current_user
    case params[:operation]
    when 'pass_email'
      if params[:present_password].empty? or not u.has_correct_password?(params[:present_password])
        session[:error] = '当前密码不正确，请确认后再试'
        redirect '/settings'
      else
        session[:info] = ''
        session[:error] = ''
        unless params[:new_password].empty? and params[:new_password_confirm].empty?
          u.change_password(params[:new_password], params[:new_password_confirm]) ? session[:info] << '密码设置成功<br/>' : session[:error] << '密码修改失败<br/>'
        end
        unless params[:email].empty?
          u.change_email(params[:email]) ? session[:info] << '邮箱设置成功' : session[:error] << '邮箱修改失败'
        end
        session[:info] = nil  if session[:info] == ''
        session[:error] = nil if session[:error] == ''
        redirect '/settings'
      end
    else
      halt 404
    end
  end

  get '/favourites' do
    require_login
    @title = '个人收藏'
    @header_nav = :user
    @user = current_user
    @posts = paginate_posts(current_user.favourites, :sort_by => :created_at, :order => 'DESC')
    haml :post_list
  end

  get '/u/:name' do
    @title = "#{params[:name]}的帖子"
    @user = User.first :name => params[:name]
    halt 404 unless @user
    @brand = "@#{@user.name}"
    @header_nav = :user
    @posts = paginate_posts(@user.monitored_posts.to_a.
                              select{|i| i.visible?(current_user) }.
                              sort_by{|i| i.created_at}.
                              reverse)
    haml :user_post_list
  end
end
