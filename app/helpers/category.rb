module LoboHelpers

    # top20 categories with most posts
    def hot_categories
      return @hot_categories  if @hot_categories
      k = :hot_categories
      key = Category.key[k]
      Category.expire(k, app_settings(:hot_categories_cache_time)) do
        hot = Category.all.to_a.sort_by(&:size).reverse[0...19]
        Category.db.multi do
          hot.each { |c| Category.db.rpush(key, c.id) }
        end
      end
      @hot_categories = Ohm::List.new(key, Category.key, Category).to_a
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
        0 => 'default',
        1 => 'success',
        2 => 'info',
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

    # paginate categories
    #
    #   :opts   options to pass on to pagination
    #
    def paginate_categories(categories, opts)
      paginate(categories, {:page => params[:p], :per_page => 25}.merge(opts))
    end

    # Wrapper to do Redis::Search category search, and convert redis search result
    # to an Array of category objects
    #
    def search_categories(query, options = {}) 
      result = Redis::Search.query('Category', query, options)
      result.empty? ? [ ] : result.map{|cat| Category[cat['id']]}
    end
end

