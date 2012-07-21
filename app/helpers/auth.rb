class Main
  helpers do

    # Use user feeded user name and password to login
    def authenticate(params)
      session[:user] = User.authenticate(params[:login_name], params[:login_password]).id
    end

    # Use feeded data to create a new user
    def register(params)
      User.new(:name => params[:name],
                  :password => params[:password],
                  :password_confirmation => params[:password_confirmation],
                  :email => params[:email].empty? ? nil : params[:email]
                 )
    end

    def current_user
      @current_user ||= User[session[:user]] if session[:user]
    end

    # Return true if current user is logged in 
    def logged_in?
      ! current_user.nil?
    end

    # redirect to login path unless logged_in
    def require_login
      remember_path
      redirect '/login' unless logged_in?
    end

    # remember current path in session for future
    def remember_path
      session[:old_path] = request.fullpath
    end

    # redirect back or a default page
    def redirect_back_or(default)
      if session[:old_path]
        path = session.delete(:old_path)
        redirect path
      else
        redirect default
      end
    end

    # generate a random link to reset password, the link expires in 10 minutes
    #
    def password_reset_url(user)
      hex = user.create_password_reset_hash
      "/reset_password/#{user.id}/#{hex}"
    end
  end
end
