class Main
  helpers do

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
      an = unread_replies.select{|k, v| k == comment.post.id or k =~ /\A#{comment.post.id}_/ }.first
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
  end
end

