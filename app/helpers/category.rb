class Main
  helpers do

    # top10 categories with most posts
    # TODO: move this part to cron job
    def hot_categories
      Category.all.sort(:limit => [0, 10])
    end

    def all_category_names
      Category.all.collect(&:display_name).to_s
    end

    # create a new category
    def new_category(params)
      Category.new(params)
    end

    # create a label for displaying category
    def category_label(category)
      %Q{<span class="#{category_label_class(category)}">#{link_to category.display_name, category_path(category)}</span>}
    end

    # classes for a category when displaying
    def category_label_class(category)
      label_tag = {
        0 => 'info',
        1 => 'success',
        2 => 'default',
        3 => 'warning',
        4 => 'important',
      }[category.rate]
      "label label-#{label_tag}"
    end

    def category_subscribe?(category)
      if logged_in?
        return current_user.subscriptions.include? category
      else
        return false
      end
    end

    def category_pending_subscribe?(category)
      if logged_in?
        return category.pending_subscribers.sort(:get => :user_id).include? current_user.id
      else
        return false
      end
    end

  end
end

