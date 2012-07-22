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

  get '/u/:name' do
    @title = "#{params[:name]}的帖子"
    @user = User.first :name => params[:name]
    halt 404 unless @user
    @posts = paginate_posts(all_viewable_posts.find(:author_id => @user.id), 
                            :sort_by => :created_at, 
                            :order => 'DESC')
    haml :home
  end
end
