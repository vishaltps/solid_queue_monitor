module SolidQueueMonitor
  class BasePresenter
    include ActionView::Helpers::DateHelper
    include ActionView::Helpers::TextHelper
    include Rails.application.routes.url_helpers
    include SolidQueueMonitor::Engine.routes.url_helpers

    def default_url_options
      { only_path: true }
    end

    def section_wrapper(title, content)
      <<-HTML
        <div class="section-wrapper">
          <div class="section">
            #{content}
          </div>
        </div>
      HTML
    end

    def generate_pagination(current_page, total_pages)
      return '' if total_pages <= 1
      
      html = '<div class="pagination">'
      
      # Previous page link
      if current_page > 1
        html += "<a href=\"?page=#{current_page - 1}#{query_params}\" class=\"pagination-link pagination-nav\">Previous</a>"
      else
        html += '<span class="pagination-link pagination-nav disabled">Previous</span>'
      end
      
      # Page links
      (1..total_pages).each do |page|
        if page == current_page
          html += "<span class=\"pagination-current\">#{page}</span>"
        else
          html += "<a href=\"?page=#{page}#{query_params}\" class=\"pagination-link\">#{page}</a>"
        end
      end
      
      # Next page link
      if current_page < total_pages
        html += "<a href=\"?page=#{current_page + 1}#{query_params}\" class=\"pagination-link pagination-nav\">Next</a>"
      else
        html += '<span class="pagination-link pagination-nav disabled">Next</span>'
      end
      
      html += '</div>'
      html
    end

    def calculate_visible_pages(current_page, total_pages)
      if total_pages <= 7
        (1..total_pages).to_a
      else
        case current_page
        when 1..3
          [1, 2, 3, 4, :gap, total_pages]
        when (total_pages - 2)..total_pages
          [1, :gap, total_pages - 3, total_pages - 2, total_pages - 1, total_pages]
        else
          [1, :gap, current_page - 1, current_page, current_page + 1, :gap, total_pages]
        end
      end
    end

    def format_datetime(datetime)
      return '-' unless datetime
      datetime.strftime('%Y-%m-%d %H:%M:%S')
    end

    def format_arguments(arguments)
      return '-' unless arguments.present?
      
      # For ActiveJob format
      if arguments.is_a?(Hash) && arguments['arguments'].present?
        return "<code>#{arguments['arguments'].inspect}</code>"
      elsif arguments.is_a?(Array) && arguments.length == 1 && arguments[0].is_a?(Hash) && arguments[0]['arguments'].present?
        return "<code>#{arguments[0]['arguments'].inspect}</code>"
      end
      
      # For regular arguments format
      "<code>#{arguments.inspect}</code>"
    end

    def format_hash(hash)
      return '-' unless hash.present?
      
      formatted = hash.map do |key, value|
        "<strong>#{key}:</strong> #{value.to_s.truncate(50)}"
      end.join(', ')
      
      "<code>#{formatted}</code>"
    end

    # Helper method to get the current request path
    def request_path
      # Try to get the current path from the controller's request
      if defined?(controller) && controller.respond_to?(:request)
        controller.request.path
      else
        # Fallback to a default path if we can't get the current path
        "/solid_queue"
      end
    end

    # Helper method to get the mount point of the engine
    def engine_mount_point
      path_parts = request_path.split('/')
      if path_parts.length >= 3
        "/#{path_parts[1]}/#{path_parts[2]}"
      else
        "/solid_queue"
      end
    end

    private

    def query_params
      params = []
      params << "class_name=#{@filters[:class_name]}" if @filters && @filters[:class_name].present?
      params << "queue_name=#{@filters[:queue_name]}" if @filters && @filters[:queue_name].present?
      params << "status=#{@filters[:status]}" if @filters && @filters[:status].present?
      
      params.empty? ? '' : "&#{params.join('&')}"
    end

    # Helper method to get the full path for a route
    def full_path(route_name, *args)
      begin
        # Try to use the engine routes first
        SolidQueueMonitor::Engine.routes.url_helpers.send(route_name, *args)
      rescue NoMethodError
        # Fall back to main app routes
        Rails.application.routes.url_helpers.send("solid_queue_#{route_name}", *args)
      end
    end
  end
end