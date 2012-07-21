#!/usr/bin/env ruby
# coding: utf-8
#Description: 

class Main
  # create a new comment
  #
  #  params:
  #   :parent_hash     parent of the comment, can be Post or Comment
  #   :content         content of the comment
  #
  post '/comment/new/:parent_hash' do
    require_login

    parent_class = params[:parent_hash].include?('_') ? Comment : Post
    parent = parent_class[params[:parent_hash]]

    return stamp_json(false) unless parent

    comment = new_comment(params.merge(:parent => parent, :author => current_user))

    if comment.valid?
      comment.save
      session[:new_comment] = comment.hash
      # return comment hash, redirect to be handled by ajax
      return stamp_json(true, comment.to_hash)
    else
      error_messages = parse_errors(comment.errors) do |e|
        case e
        when [:comment, :no_content]; '内容不能为空'
        end
      end.join('<br/>')
      session[:error] = error_messages
      
      # return nil as well? TODO: error messages need a more *formal* format
      return stamp_json(false, :error => error_messages)
    end
  end

  # get a single comment as JSON
  #
  # params: 
  #   :hash     comment hash
  #
  get '/comment/get/:hash' do
    c = Comment[params[:hash]]
    c.nil? ? stamp_json(false) : stamp_json(true, c.to_hash)
  end

  # edit a single comment, and return the edited comment as JSON
  # 
  # params:
  #   :content  new content to be updated
  #   :hash     comment hash
  post '/comment/edit/:hash' do
    c = Comment[params[:hash]]
    return stamp_json(false) unless c and c.author == current_user
    c.content = params[:comment_content]
    c.save
    stamp_json(true, c.to_hash)
  end
end
