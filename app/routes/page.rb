# coding: utf-8
class Main
  before do
    logger.info params.inspect  if RACK_ENV == 'development' && request.request_method == 'POST'
  end

  not_found do
    haml(:'404')
  end

  error do
    haml(:'500')
  end

  get "/" do
    @title = '主页'
    @brand = '嘟噜'
    @posts = paginate_posts(viewable_posts, :sort_by => :score, :order => 'DESC')
    haml :post_list
  end

  get "/latest" do
    @title = '最新'
    @brand = '嘟噜'
    @posts = paginate_posts(all_viewable_posts, :sort_by => :created_at, :order => 'DESC')
    haml :post_list
  end

  get '/controversial' do
    @title = '最具争议'
    @brand = '嘟噜'
    @posts = paginate_posts(viewable_posts, :sort_by => :controversy, :order => 'DESC')
    haml :post_list
  end

  get '/top' do
    @title = '分数最高'
    @brand = '嘟噜'
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
    @brand = '嘟噜'
    haml :browser, :layout => false, :format => :xhtml
  end

  get '/categories' do
    @title = '圈子列表'
    @categories = paginate_categories(Category.all.to_a.sort_by{|c| c.size}.reverse)
    haml :category_list
  end

  get '/search' do
    remember_path back
    query = params[:q]
    unless query
      session[:error] = '搜索关键字不能为空'
      redirect_back_or '/'
    end

    author = params[:u] ? User.with(:name, params[:u]) : nil
    category = params[:c] ? Category.with(:name, params[:c]) : nil
    conditions = {}
    conditions.merge!(:author_id => author.id)   if author
    conditions.merge!(:category_id => category.id)   if category
    search_type = case params[:t]
                  when /\Ac\Z|\Acategor(y|ies)*\Z/i; 'categories'
                  else; 'posts'
                  end

    case search_type
    when 'categories'
      result = search_categories(query, {:conditions => conditions})
      if result.empty?
        session[:info] = '抱歉，没有搜索到任何结果'
        redirect_back_or '/'
      else
        @title = '搜索结果'
        @categories = paginate_categories(result, :sort_by => :size, :order => 'DESC')
        haml :category_list
      end
    when 'posts'
      result = search_posts(query, {:conditions => conditions})
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
end
