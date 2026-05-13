# frozen_string_literal: true

module SolidQueueMonitor
  module SortHelper
    def sortable_header(column, label, sort:, filters: {})
      return tag.th(label) unless sort

      column_str = column.to_s
      active = sort[:sort_by] == column_str
      next_dir = active && sort[:sort_direction] == 'asc' ? 'desc' : 'asc'
      query = filters.compact.merge(sort_by: column_str, sort_direction: next_dir)

      tag.th(
        link_to(
          safe_join([label, sort_arrow(active, sort[:sort_direction])]),
          "?#{query.to_query}",
          class: class_names('sortable-header', active: active)
        )
      )
    end

    private

    def sort_arrow(active, direction)
      return ' &udarr;'.html_safe unless active

      direction == 'asc' ? ' &uarr;'.html_safe : ' &darr;'.html_safe
    end
  end
end
