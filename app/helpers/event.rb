#!/usr/bin/env ruby
# coding: utf-8
#Description: 

class Main
  helpers do
    def events
      admin_events.empty? ? commercial_events : admin_events
    end

    def admin_events
      post_review_events
    end

    def commercial_events
      [ ]
    end

    def post_review_events
      return [] unless logged_in?
      return [] unless current_user.able_to_sanction? or not current_user.moderated_categories.empty?
      pending_review = Moderation.find(:reviewer => nil).to_a
      if current_user.able_to_sanction?
        pending_review
      else
        pending_review.select{|m| m.post.category.admins.include?(current_user)}
      end
    end
  end
end
