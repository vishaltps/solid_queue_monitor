module SolidQueueMonitor
  class BasePresenter
    include ActionView::Helpers::DateHelper
    include ActionView::Helpers::TextHelper

    def section_wrapper(title, content)
      <<-HTML
        #{content}
      HTML
    end

    def generate_pagination(current_page, total_pages)
      return '' if total_pages <= 1

      links = []
      
      # Previous button
      if current_page > 1
        links << "<a href='?page=#{current_page - 1}' class='pagination-link pagination-nav'>&laquo; Previous</a>"
      else
        links << "<span class='pagination-link pagination-nav disabled'>&laquo; Previous</span>"
      end

      # Page numbers
      visible_pages = calculate_visible_pages(current_page, total_pages)
      
      visible_pages.each do |page|
        if page == :gap
          links << "<span class='pagination-gap'>...</span>"
        elsif page == current_page
          links << "<span class='pagination-current'>#{page}</span>"
        else
          links << "<a href='?page=#{page}' class='pagination-link'>#{page}</a>"
        end
      end

      # Next button
      if current_page < total_pages
        links << "<a href='?page=#{current_page + 1}' class='pagination-link pagination-nav'>Next &raquo;</a>"
      else
        links << "<span class='pagination-link pagination-nav disabled'>Next &raquo;</span>"
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
      datetime&.strftime('%Y-%m-%d %H:%M:%S')
    end

    def format_arguments(arguments)
      "<code>#{arguments}</code>"
    end
  end
end