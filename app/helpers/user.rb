module LoboHelpers
    
    def avatar_for(user, size)
      if user.email
        hash = Digest::MD5.hexdigest(user.email)
        "http://www.gravatar.com/avatar/#{hash}?s=#{size}&d=mm"
      else
        "http://www.gravatar.com/avatar/00000000000000000000000000000000?d=mm&f=y&s=#{size}"
      end
    end
end
