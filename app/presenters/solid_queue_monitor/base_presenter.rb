# frozen_string_literal: true

module SolidQueueMonitor
  class BasePresenter
    include ActionView::Helpers::DateHelper
    include ActionView::Helpers::TextHelper
    include Rails.application.routes.url_helpers
    include SolidQueueMonitor::Engine.routes.url_helpers

    def default_url_options
      { only_path: true }
    end

    def section_wrapper(_title, content)
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
      html += if current_page > 1
                "<a href=\"?page=#{current_page - 1}#{query_params}\" class=\"pagination-link pagination-nav\">Previous</a>"
              else
                '<span class="pagination-link pagination-nav disabled">Previous</span>'
              end

      # Page links
      visible_pages = calculate_visible_pages(current_page, total_pages)

      visible_pages.each do |page|
        html += if page == :gap
                  '<span class="pagination-gap">...</span>'
                elsif page == current_page
                  "<span class=\"pagination-current\">#{page}</span>"
                else
                  "<a href=\"?page=#{page}#{query_params}\" class=\"pagination-link\">#{page}</a>"
                end
      end

      # Next page link
      html += if current_page < total_pages
                "<a href=\"?page=#{current_page + 1}#{query_params}\" class=\"pagination-link pagination-nav\">Next</a>"
              else
                '<span class="pagination-link pagination-nav disabled">Next</span>'
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
      return '-' if arguments.blank?

      # Extract and format the arguments more cleanly
      formatted_args = if arguments.is_a?(Hash) && arguments['arguments'].present?
                         format_job_arguments(arguments)
                       elsif arguments.is_a?(Array) && arguments.length == 1 && arguments[0].is_a?(Hash) && arguments[0]['arguments'].present?
                         format_job_arguments(arguments[0])
                       else
                         arguments.inspect
                       end

      if formatted_args.length <= 50
        "<code class='args-single-line'>#{formatted_args}</code>"
      else
        <<-HTML
          <div class="args-container">
            <code class="args-content">#{formatted_args}</code>
          </div>
        HTML
      end
    end

    def format_hash(hash)
      return '-' if hash.blank?

      formatted = hash.map do |key, value|
        "<strong>#{key}:</strong> #{value.to_s.truncate(50)}"
      end.join(', ')

      "<code>#{formatted}</code>"
    end

    def queue_link(queue_name, css_class: nil)
      return '-' if queue_name.blank?

      classes = ['queue-link', css_class].compact.join(' ')
      "<a href=\"#{queue_details_path(queue_name: queue_name)}\" class=\"#{classes}\">#{queue_name}</a>"
    end

    def request_path
      if defined?(controller) && controller.respond_to?(:request)
        controller.request.path
      else
        '/solid_queue'
      end
    end

    def engine_mount_point
      path_parts = request_path.split('/')
      if path_parts.length >= 3
        "/#{path_parts[1]}/#{path_parts[2]}"
      else
        '/solid_queue'
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

    def full_path(route_name, *args)
      SolidQueueMonitor::Engine.routes.url_helpers.send(route_name, *args)
    rescue NoMethodError
      Rails.application.routes.url_helpers.send("solid_queue_#{route_name}", *args)
    end

    def format_job_arguments(job_data)
      args = if job_data['arguments'].is_a?(Array)
               if job_data['arguments'].first.is_a?(Hash) && job_data['arguments'].first['_aj_ruby2_keywords'].present?
                 job_data['arguments'].first.except('_aj_ruby2_keywords')
               else
                 job_data['arguments']
               end
             else
               job_data['arguments']
             end

      args.inspect
    end
  end
end
