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
      
      links = []
      
      # Previous page link
      if current_page > 1
        links << "<a href='?page=#{current_page - 1}#{query_params}' class='pagination-link'>&laquo; Previous</a>"
      else
        links << "<span class='pagination-link disabled'>&laquo; Previous</span>"
      end
      
      # Page number links
      if total_pages <= 7
        # Show all pages if there are 7 or fewer
        (1..total_pages).each do |page|
          links << page_link(page, current_page)
        end
      else
        # Show first page, last page, and pages around current
        links << page_link(1, current_page)
        
        if current_page > 3
          links << "<span class='pagination-gap'>...</span>"
        end
        
        start_page = [current_page - 1, 2].max
        end_page = [current_page + 1, total_pages - 1].min
        
        (start_page..end_page).each do |page|
          links << page_link(page, current_page)
        end
        
        if current_page < total_pages - 2
          links << "<span class='pagination-gap'>...</span>"
        end
        
        links << page_link(total_pages, current_page)
      end
      
      # Next page link
      if current_page < total_pages
        links << "<a href='?page=#{current_page + 1}#{query_params}' class='pagination-link'>Next &raquo;</a>"
      else
        links << "<span class='pagination-link disabled'>Next &raquo;</span>"
      end
      
      <<-HTML
        <div class="pagination">
          #{links.join}
        </div>
      HTML
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
      
      if arguments.is_a?(Array) && arguments.length == 1 && arguments[0].is_a?(Hash)
        # Handle ActiveJob-style arguments
        format_hash(arguments[0])
      else
        "<code>#{arguments.to_json}</code>"
      end
    end

    def format_hash(hash)
      return '-' unless hash.present?
      
      formatted = hash.map do |key, value|
        "<strong>#{key}:</strong> #{value.to_s.truncate(50)}"
      end.join(', ')
      
      "<code>#{formatted}</code>"
    end

    private

    def page_link(page, current_page)
      if page == current_page
        "<span class='pagination-current'>#{page}</span>"
      else
        "<a href='?page=#{page}#{query_params}' class='pagination-link'>#{page}</a>"
      end
    end

    def query_params
      params = []
      params << "class_name=#{CGI.escape(@filters[:class_name])}" if @filters && @filters[:class_name].present?
      params << "queue_name=#{CGI.escape(@filters[:queue_name])}" if @filters && @filters[:queue_name].present?
      params << "status=#{CGI.escape(@filters[:status])}" if @filters && @filters[:status].present?
      
      params.empty? ? '' : "&#{params.join('&')}"
    end
  end
end