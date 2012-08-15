#!/usr/bin/env ruby
# coding: utf-8
#Description: 

class Main
  # all subscribed content
  #
  # THIS ROUTE MUST BE PUT AHEAD OF /l/:category ROUTE
  #
  get '/l/all' do
    if current_user and not current_user.subscriptions.empty?
      categories = current_user.subscriptions.to_a
    else
      categories = hot_categories
    end
    posts = available_posts_in_categories(categories)
    @posts = paginate_posts(posts, :sort_by => :score, :order => 'DESC')

    haml :post_list
  end

  # get a random category
  #
  # THIS ROUTE MUST BE PUT AHEAD OF /l/:category ROUTE
  #
  get '/l/random' do
    cids = Category.all.map(&:id)
    begin
      c = cids.sample
    end until Category[c].allow_viewing? current_user
    redirect category_path Category[c]
  end

  # show detail of a catgory or a mixture of categories joined by '+'
  get '/l/:categories' do
    categories = params[:categories].split('+').compact.collect{|c| Category.first(:name => c)}
    case categories.size
    when 0      # no such category ?
      halt 404
    when 1      # only one category
      @title = categories.first.display_name
      @category = categories.first
      if @category.allow_viewing? current_user
        post_set = available_posts_in_categories(categories)
        @posts = paginate_posts(post_set, :sort_by => :score, :order => 'DESC')
        haml :post_list
      else
        haml :not_authorized_to_view
      end
    else        # mixed categories
      viewables = categories.select{|c| c.allow_viewing?(current_user) }
      viewables.each {|c| halt 404 unless c}
      @title = '混合类别'
      post_set = available_posts_in_categories(viewables)
      @posts = paginate_posts(post_set, :sort_by => :score, :order => 'DESC')
      haml :post_list
    end
  end

  get '/l/:category/settings' do
    halt 404 unless logged_in?
    @category = Category.with(:name, params[:category])
    halt 404 unless @category
    halt 404 unless current_user.tagged?('admin') or @category.admins.include?(current_user)
    haml :'category/settings'
  end

  post '/l/:category/settings' do
    halt 404 unless logged_in?
    @category = Category.with(:name, params[:category])
    halt 404 unless @category
    halt 404 unless current_user.tagged?('admin') or @category.admins.include?(current_user)
    case params[:operation]
    when 'notes'
      @category.note = params[:note]
      @category.sidebar = params[:sidebar]
      @category.save
      session[:info] = '描述修改成功'
      redirect category_path(@category)
    when 'add_admin'
      @category.add_admin(params[:user])
      @category.save
      session[:info] = '添加管理员成功'
      redirect category_path(@category)
    else
      halt 404
    end
  end

  # enquire categories with a :keyword in either name or display_name
  # TODO
  get '/q/category/:keyword' do

  end

  # new category page
  get '/category/new' do
    require_login
    @title = '建立新类别'
    haml :'category/new'
  end

  # create a new category
  post '/category/new' do
    require_login
    category = new_category(params)
    if category.valid?
      category.save
      current_user.subscribe category
      category.add_admin current_user
      redirect category_path(category)
    else
      error_messages = parse_errors(category.errors) do |e|
        case e
        when [:name, :not_present]       ; '类别英文名是必须的'
        when [:name, :not_unique]        ; "类别名#{category.name}已经存在"
        when [:name, :reserved_name]     ; "类别名#{category.name}不可用"
        when [:display_name, :not_unique]; "类别#{category.display_name}已经存在"
        when [:name, :format]            ; '英文名不能太短，也不能太长，最多30个字符，也不可以用中文哦'
        end
      end.join('<br/>')
      session[:error] = error_messages
      @title = '建立新类别'
      haml :'category/new'
    end
  end

  # get names of all categories 
  get '/category/get' do
    return stamp_json(false) unless logged_in? 
    categories = Category.all.collect(&:display_name)
    return stamp_json(true, {:names => categories})
  end

  # get description of a single category
  get '/category/get/:name' do
    return stamp_json(false) unless logged_in? and category = Category.first(:name => params[:name])
    return stamp_json(true, category.to_hash)
  end

  # subscribe a :Category or unsubscribe if already subscribed
  #
  #   :category => category name
  #
  post '/category/subscribe/:category' do
    return stamp_json(false) unless logged_in?
    category = Category.first(:name => params[:category])
    return stamp_json(false) unless category
    if current_user.subscriptions.include? category
      current_user.unsubscribe category
      return stamp_json(true, :action => 'unsubscribe')
    else
      if not category.subscription_review_required?
        current_user.subscribe category
        return stamp_json(true, {:action => 'subscribe', :result => 'accept'})
      elsif category.pending_subscribers.include? current_user
        return stamp_json(false)
      else
        category.add_pending_subscriber current_user
        return stamp_json(true, {:action => 'subscribe', :result => 'pending'})
      end
    end
    nil
  end
end
