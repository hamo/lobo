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
      return [] unless current_user.able_to_sanction? or not current_user.moderated_categories.empty?
      pending_review = Action.find
    end
  end
end
