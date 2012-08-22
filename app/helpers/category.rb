class Main
  helpers do

    # top10 categories with most posts
    def hot_categories
      return @hot_categories  if @hot_categories
      k = :hot_categories
      key = Category.key[k]
      if key.exists
        @hot_categories = Ohm::List.new(key, Category.key, Category).to_a
        return @hot_categories
      end

      @hot_categories = Category.all.to_a.sort_by(&:size).reverse[0...9]
      Category.db.multi do
        @hot_categories.each { |c| Category.db.rpush(key, c.id) }
        Category.db.expire(key, app_settings(:hot_categories_cache_time))
      end
      return @hot_categories
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

