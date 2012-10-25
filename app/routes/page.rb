# coding: utf-8
class Main
  not_found do
    haml(:'404')
  end

  error do
    haml(:'500')
  end

  get "/" do
    @title = '主页'
    @posts = paginate_posts(viewable_posts, :sort_by => :score, :order => 'DESC')
    haml :post_list
  end

  get "/latest" do
    @title = '最新'
    @posts = paginate_posts(all_viewable_posts, :sort_by => :created_at, :order => 'DESC')
    haml :post_list
  end

  get '/controversial' do
    @title = '最具争议'
    @posts = paginate_posts(viewable_posts, :sort_by => :controversy, :order => 'DESC')
    haml :post_list
  end

  get '/top' do
    @title = '分数最高'
    @posts = paginate_posts(viewable_posts, :sort_by => :karma, :order => 'DESC')
    haml :post_list
  end

  get '/d/:domain' do
    @title = "来自 #{params[:domain]}"
    @posts = paginate_posts(all_viewable_posts.find(:domain => params[:domain]), 
                           :sort_by => :score, 
                           :order => 'DESC')
    haml :post_list
  end

  get '/browser' do
    @title = "请升级您的浏览器"
    haml :browser, :layout => false, :format => :xhtml
  end

  get '/search' do
    query = params[:q]
    unless query
      session[:error] = '搜索关键字不能为空'
      redirect_back_or '/'
    end
    result = search_posts(query)
    if result.empty?
      session[:info] = '抱歉，没有搜索到任何结果'
      redirect_back_or '/'
    else
      @title = '搜索结果'
      @posts = paginate_posts(result, :sort_by => :karma, :order => 'DESC')
      haml :post_list
    end
  end
end
