#!/usr/bin/env ruby
# coding: utf-8
#Description: 

class Main
  helpers do
    def events
      admin_events.empty? ? commercial_events : admin_events
    end

    def admin_events
      post_review_events + subscription_events
    end

    def commercial_events
      [ ]
    end

    def post_review_events
      return [] unless logged_in?
      return [] unless current_user.able_to_sanction? or not current_user.moderated_categories.empty?
      pending_review = Moderation.find(:reviewer => nil).to_a.select{|m| m.reporter != current_user}
      if current_user.able_to_sanction?
        pending_review
      else
        pending_review.select{|m| m.post.category.admins.include?(current_user)}
      end
    end

    def subscription_events
      return []   unless logged_in? and current_user.moderated_categories.empty?
      current_user.moderated_categories.to_a.collect{|c|
        Subscription.find(:category_id => c.id).to_a
      }.flatten
    end
  end
end
