#!/usr/bin/env ruby
# coding: utf-8
#Description: 

class Main
  # vote a :Post or a :Comment
  #
  #   :hash => hash of post or comment
  #   :vote_type => :up or :down
  #
  post '/do/vote' do
    return nil unless logged_in?
    article_class = params[:hash].include?('_') ? Comment : Post
    article = article_class[params[:hash]]
    return nil unless article
    current_user.vote(article, params[:vote_type].to_sym)
    nil
  end

  # sanction a :Post
  #
  #   :hash => hash of post
  #
  post '/do/sanction' do
    return stamp_json(false) unless logged_in? and params[:hash]
    p = Post[params[:hash]]
    return stamp_json(false) unless p and current_user.able_to_sanction?(p)
    current_user.sanction(p)
    return stamp_json(true)
  end

  # report a post to have in appropriate content
  #
  #   :hash => hash of post
  #
  post '/do/report' do
    return stamp_json(false) unless logged_in? and current_user.able_to_report?
    article = Post[params[:hash]]
    return stamp_json(false) unless article
    result = current_user.report(article, :memo => params[:memo])
    return stamp_json(result)
  end

  # review a post, tag appropriate content "approved"
  #
  #   :hash     => hash of post
  #   :approved => 'yes' or 'no'
  #
  post '/do/review' do
    return stamp_json(false) unless logged_in?
    article = Post[params[:hash]]
    return stamp_json(false) unless article and article.reported_by
    return stamp_json(false) unless current_user.able_to_review?( article )
    approved = ( params[:approved] == 'yes' ? true : false )
    if current_user.review(article, approved)
      return stamp_json(true)
    end
    return stamp_json(false)
  end

  # authorize a user subscription
  #
  #   :user       => id of user
  #   :category   => id of category
  #   :approved   => 'yes' or 'no'
  #
  post 'do/authorize_subscription' do
    return stamp_json(false) unless logged_in?
    u = User[params[:user]]
    return stamp_json(false) unless u
    c = Category[params[:category]]
    return stamp_json(false) unless c
    return stamp_json(false) unless Category.admins.include? current_user
    approved = ( params[:approved] == 'yes' ? true : false )
    if approved
      category.accept_pending_subscriber
    else
      category.reject_pending_subscriber
    end
    return stamp_json(true)
  end
end

