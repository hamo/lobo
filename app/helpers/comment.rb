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

  end
end

