class Main
  helpers do

    # Your helpers go here. You can also create another file in app/helpers with the same format.
    # All helpers defined here will be available across all the application.
    #
    # @example A helper method for date formatting.
    #
    #   def format_date(date, format = "%d/%m/%Y")
    #     date.strftime(format)
    #   end
    #
    # Generate HAML and escape HTML by default.
    def haml(template, options = {}, locals = {})
      #options[:escape_html] = true unless options.include?(:escape_html)
      super(template, options, locals)
    end

    # Render a partial and pass local variables.
    #
    # Example:
    #   != partial :games, :players => @players
    #def partial(template, locals = {})
    #  haml(('_' + template.to_s).to_sym, {:layout => false}, locals)
    #end
    def partial(template, *args)
      template_array = template.to_s.split('/')
      template = template_array[0..-2].join('/') + "/_#{template_array[-1]}"
      options = args.last.is_a?(Hash) ? args.pop : {}
      options.merge!(:layout => false)
      locals = options[:locals] || {}
      if collection = options.delete(:collection) then
        collection.inject([]) do |buffer, member|
          buffer << erb(:"#{template}", options.merge(:layout =>
          false, :locals => {template_array[-1].to_sym => member}.merge(locals)))
        end.join("\n")
      else
        haml(:"#{template}", options)
      end
    end

    # shortcut to logger
    def logger
      $logger
    end

    # link_to from sinatra-static-asset with icon support
    #
    def link_to(title, href, opts = {})
      return super unless opts.key?(:icon) or opts.key?(:icon_after)
      after = true  if opts.key? :icon_after
      icon = opts.delete(:icon) || opts.delete(:icon_after)
      opts = opts.merge(:href => href)
      if after
        %Q{<a #{opts.collect{|k,v| "#{k}='#{v}'"}.join(" ")}>
        #{title}
        <i class="#{icon}"></i>
        </a>}
      else
        %Q{<a #{opts.collect{|k,v| "#{k}='#{v}'"}.join(" ")}>
        <i class="#{icon}"></i>
        #{title}
        </a>}
      end
    end
  end
end
