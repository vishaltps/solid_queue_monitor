# frozen_string_literal: true

module SolidQueueMonitor
  module PaginationHelper
    def visible_pages(current_page, total_pages)
      return (1..total_pages).to_a if total_pages <= 7

      case current_page
      when 1..3
        [1, 2, 3, 4, :gap, total_pages]
      when (total_pages - 2)..total_pages
        [1, :gap, total_pages - 3, total_pages - 2, total_pages - 1, total_pages]
      else
        [1, :gap, current_page - 1, current_page, current_page + 1, :gap, total_pages]
      end
    end

    def pagination_href(page, extra_params = {})
      query = request.query_parameters.merge(extra_params).merge(page: page)
      "?#{query.to_query}"
    end
  end
end
