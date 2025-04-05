# frozen_string_literal: true

module SolidQueueMonitor
  class PaginationService
    def initialize(relation, page, per_page)
      @relation = relation
      @page = page
      @per_page = per_page
    end

    def paginate
      {
        records: paginated_records,
        total_pages: total_pages,
        current_page: @page
      }
    end

    private

    def offset
      (@page - 1) * @per_page
    end

    def total_pages
      (@relation.count.to_f / @per_page).ceil
    end

    def paginated_records
      @relation.limit(@per_page).offset(offset)
    end
  end
end
