class Main
  helpers do

    # Add the post page viewing to history so that the history can
    # be displayed in sidebar. History contains 6 pages, the last is
    # current page, but only first 5 should be displayed.
    def add_to_history(post)
      session[:history] ||= []
      unless session[:history].include? post.hash
        session[:history].push( post.hash )
      end
      session[:history].shift while session[:history].length > 6
    end

    # create a new post from submitted information
    def new_post(params)
      case params[:type]
      when 'url'
        Post.new(:title => params[:title], 
                    :url => params[:url],
                    :category => Category.with(:display_name, params[:category]) ,
                    :author => current_user
                   )
      when 'content'
        Post.new(:title => params[:title], 
                    :content => params[:content],
                    :category => Category.with(:display_name, params[:category]) ,
                    :author => current_user
                   )
      end
    end

    # brands are icons placed in post title line to indicate some information
    # about the post, i.e. picture/video or a hot topic
    #
    def post_brands(post)
      brands = []
      brands << :picture  if post.url =~ /\.(jpg|png|jpeg|gif)$/i
      brands
    end

    # paginate posts
    #
    #   :opts   options to pass on to pagination
    #
    def paginate_posts(posts, opts)
      paginate(posts, {:page => params[:p], :per_page => 25}.merge(opts))
    end

    # all viewable posts
    def all_viewable_posts(user = current_user)
      posts = Post.seek_public
      return posts unless user
      user.subscriptions.each {|c| posts.union :category_id => c.id }

      posts.except(:available? => false)
    end

    # all public viewable posts + all subscribed posts, WITHIN a period
    #
    # options
    #
    #   :user     => user who views, default to current user
    #   :time     => which period to cover up to now, 
    #                return everything if this value is 0
    #                default to 24 hours (24*3600)
    #   :timeout  => timeout value for search keys, default 300
    #
    def viewable_posts(opts = {})
      opts = {
        :user => current_user,
        :time => params[:t] ? params[:t].downcase : 'week',
        :timeout => app_settings(:post_sorting_cache_time),
      }.merge(opts)
      opts[:time] = case opts[:time]
                    when 'day';     86400
                    when 'week';    604800
                    when 'month';   2592000
                    when 'all';     0
                    else;           604800
                    end

      # key for temp storage of results, expires in 5 minutes
      #   
      #   <user_id>_viewable_<period>   for a specific user
      #   viewable_<period>             for general public
      #
      k = ( (opts[:user] ? "#{opts[:user].id}_" : "") + "viewable_#{opts[:time]}" ).to_sym
      return Ohm::Set.new(Post.key[k], Post.key, Post)   if Post.key[k].exists
      key = Post.key[k]

      # all public viewable posts
      posts = Post.seek_public
      # all subscribed posts
      opts[:user].subscriptions.each {|c| posts.union :category_id => c.id }   if opts[:user]
      # except deleted ones
      posts = posts.except(:available? => false)

      # return all if period is 0
      key0 = key.sub(opts[:time].to_s, '0')
      res0 = posts.save(key0)
      Post.db.expire(key0, opts[:timeout])
      return res0     if opts[:time].zero?

      # filter out posts within selected period, and store result in a temp key
      # which expires in :timeout seconds
      latest_posts = Post.latest_within(opts[:time], opts[:timeout])
      Post.db.sinterstore(key, key0, latest_posts.key)
      res = Ohm::Set.new(key, Post.key, Post)
      Post.db.expire(key, opts[:timeout])

      return res
    end

    # available posts in categories, the posts that are not deleted or otherwise
    # under karma barrier
    #
    def available_posts_in_categories(category_set)
      post_set = category_set.first.posts
      category_set[1..-1].each {|c| post_set = post_set.union(:category_id => c.id)} if category_set.size > 1
      post_set.except(:available? => false)
    end
  end
end

