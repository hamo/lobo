#!/usr/bin/env ruby
# coding: utf-8
#Author: Roy L Zuo (roylzuo at gmail dot com)
#Description: 

module LoboHelpers

    # return path of a Post object
    #
    def post_path(post)
      "/p/#{post.hash}"
    end

    # Return a domain related path
    #
    def domain_path(post)
      if post.url
        "/d/#{post.domain}"
      else
        "/l/#{post.category.name}"
      end
    end

    # Return a category path
    def category_path(category)
      category ? "/l/#{category.name}" : "/l/uncategoried"
    end

    # Return a path to a comment
    def comment_path(comment)
      "/p/#{comment.hash.sub('_','#')}"
    end

    # return all posts by a user
    #
    def user_path(user)
      "/u/#{user.name}"
    end
    
    # current url path
    # 
    def current_path
      request.path_info
    end
end
