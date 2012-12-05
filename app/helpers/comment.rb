module LoboHelpers

    # create a new post from submitted information
    #
    def new_comment(params)
      Comment.new(
                  :content => params[:comment_content], 
                  :parent => params[:parent],
                  :author => current_user
                 )
    end

    # is current comment a new reply for current user?
    def is_new_reply?(comment)
      return false unless unread_replies
      an = unread_replies.select{|k, _| k == comment.post.id or k =~ /\A#{comment.post.id}_/ }.first
      return false unless an
      unread_replies[an.first].include? comment.id
    end

    # total new replies number for current user
    #
    def total_unread
      return 0 unless unread_replies
      return 0 if unread_replies.empty?
      unread_replies.values.compact.inject(&:+).size
    end
      
    # unread comment counters
    def unread_replies
      return nil unless logged_in? and current_user.unread_replies
      current_user.unread_replies.select{|id, _|
        (Post[id] ? 
         Post[id].visible?(current_user): 
         (Comment[id] ? Comment[id].visible?(current_user) : nil) 
        )
      }
    end

    # unread replies for a specific post
    def unread_replies_for_post(post)
      return 0 unless unread_replies
      unread_replies.select{|k, _| k == post.id || k =~ /\A#{post.id}_/ }.collect(&:last).flatten.size
    end

    # unread replies for a specific comment
    def unread_replies_for_comment(comment)
      return 0 unless unread_replies and unread_replies[comment.id]
      unread_replies[comment.id].size
    end

    # a specific user's comments for a specific post
    # returns an array
    #
    # [
    #   [comment_id,  [sub_comment_id, .... ]],
    #   ...
    # ]
    def user_comments_for_post(user, post)
      all = user.comments.find(:post_id => post.id)
      res = {}
      all.each do |c|
        next if c.ancestors.any?{|an| all.include? an }
        res[c.id] = []
      end
      all.each do |c|
        c.ancestors.reverse.each do |an|
          if all.include? an
            res[an.id] << c.id
            break
          end
        end
      end
      res.sort_by{|a, _| Comment[a].created_at}
    end

end

