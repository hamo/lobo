module LoboHelpers

    # Add the post page viewing to history so that the history can
    # be displayed in sidebar. History contains 6 pages, the last is
    # current page, but only first 5 should be displayed.
    def add_to_history(post)
      session[:history] ||= []
      unless session[:history].include? post.hash
        session[:history].push( post.hash )
        add_to_new_post_readers(post, current_user) if new_post?(post)
      end
      session[:history].shift while session[:history].length > 5
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
      when 'post_content'
        Post.new(:title => params[:title], 
                    :content => params[:post_content],
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
      brands << :text     if post.type == :content
      brands
    end

    # paginate posts
    #
    #   :opts   options to pass on to pagination
    #
    def paginate_posts(posts, opts = {})
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
      key = Post.key[k]
      Post.expire(k, opts[:timeout]) do
        # all public viewable posts
        posts = Post.seek_public
        # all subscribed posts
        opts[:user].subscriptions.each {|c| posts.union :category_id => c.id }   if opts[:user]
        # except deleted ones
        posts = posts.except(:available? => false)

        # return all if period is 0
        key0 = key.sub(opts[:time].to_s, '0')
        res0 = posts.save(key0)
        break   if opts[:time].zero?

        # filter out posts within selected period, and store result in a temp key
        # which expires in :timeout seconds
        latest_posts = Post.latest_within(opts[:time], opts[:timeout])
        Post.db.sinterstore(key, key0, latest_posts.key)
      end
      Ohm::Set.new(key, Post.key, Post)
    end

    # if a post is read by a user within new_post_timeout
    #
    def new_post_read?(post, user)
      return true   unless new_post?(post) and user
      post.key[:new_post_readers].sismember(user.id)
    end

    def new_post?(post)
      (Time.now.to_i - post.created_at.to_i) < app_settings(:new_post_timeout)
    end

    # add an user to reader list of new post
    #
    def add_to_new_post_readers(post, user)
      post.key[:new_post_readers].sadd(user.id) 
    end

    # available posts in categories, the posts that are not 
    #   deleted
    #
    def available_posts_in_categories(category_set)
      post_set = category_set.first.posts
      category_set[1..-1].each {|c| post_set = post_set.union(:category_id => c.id)} if category_set.size > 1
      post_set.except(:available? => false)
    end

    # sanity check for url
    def url_check(url)
      url_pattern = /\A(http|https):\/\/([a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}|(25[0-5]|2[0-4]\d|[0-1]?\d?\d)(\.(25[0-5]|2[0-4]\d|[0-1]?\d?\d)){3}|localhost)(:[0-9]{1,5})?(\/.*)?\z/ix
      return url.match(url_pattern)
    end

    # Wrapper to do Redis::Search post search, and convert redis search result
    # to an Array of post objects
    #
    def search_posts(query, options = {}) 
      result = Redis::Search.query('Post', query, options)
      result.empty? ? [ ] : result.map{|po| Post[po['id']]}.select{|po| po.visible?(current_user)}
    end
end

