#!/usr/bin/env ruby
# coding: utf-8
#Description: 
require 'uri'

class Main
  # show post detail
  get '/p/:hash' do
    @post = Post[params[:hash]]
    halt 404 unless @post and @post.visible? current_user
    @title = @post.title
    @brand = "{#{@post.category.display_name}}"
    haml(:'post/detail')
  end

  # clear unread counter after visiting a post page
  after '/p/:hash' do
    @post = Post[params[:hash]]
    if logged_in?
      current_user.clear_unread_replies(@post)
    end
  end

  # new post page
  get '/post/new' do
    require_login
    @title = '发表新帖子'
    haml :'post/new'
  end

  # create a new post
  post '/post/new' do
    require_login
    unless current_user.able_to_post?
      session[:error] = '您最近的帖子表现不佳，请休息几天再回来发帖吧'
      redirect '/post/new'
    end
    post = new_post(params)
    if post.valid?
      post.save
      session[:new_post] = post.hash
      redirect post_path(post)
    else
      error_messages = parse_errors(post.errors) do |e|
        case e
        when [:title, :not_present];         '英雄，起码留个标题吧～～～'
        when [:title, :too_long];            '标题不能超过200字符'
        when [:post, :no_body];              '不是这么绝情吧，写点内容啊'
        when [:category, :private_category]; '未订阅用户不能发布分享'
        when [:category, :not_present];      '请输入或选择一个有效类别'
        when [:category, :type_not_allowed]; "该分类不允许#{post.type == :url ? '链接' : '文字'}贴"
        end
      end.join('<br/>')
      session[:error] = error_messages
      @title = '发表新贴子'
      haml :'post/new'
    end
  end

  # get a single post as JSON
  #
  # params: 
  #   :hash     post hash
  #
  get '/post/get/:hash' do
    po = Post[params[:hash]]
    po.nil? ? stamp_json(false) : stamp_json(true, po.to_hash)
  end

  # edit a single post, and return the edited post as JSON
  # 
  # params:
  #   :content  new content to be updated
  #   :url      url of post
  #   :hash     post hash
  post '/post/edit/:hash' do
    po = Post[params[:hash]]
    return stamp_json(false) unless po and po.visible? and po.author == current_user
    if po.url  # url post?
      po.url = params[:post_url]
    else
      po.content = params[:post_content]
    end
    po.save
    stamp_json(true, po.to_hash)
  end

  # delete a single post, return status as JSON
  #
  # params:
  #   :hash   post hash
  post '/post/delete/:hash' do
    po = Post[params[:hash]]
    return stamp_json(false) unless po and po.visible? and po.author == current_user
    po.add_tag 'deleted'
    stamp_json(true)
  end
  
  # add a post to history
  post '/session/add_history' do
    return nil unless logged_in?
    po = Post[params[:hash]]
    add_to_history(po) if po
  end
end
