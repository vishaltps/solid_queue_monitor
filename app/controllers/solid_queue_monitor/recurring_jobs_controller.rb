# frozen_string_literal: true

module SolidQueueMonitor
  class RecurringJobsController < BaseController
    SORTABLE_COLUMNS = %w[key class_name queue_name priority].freeze

    def index
      base_query = filter_recurring_jobs(SolidQueue::RecurringTask.all)
      sorted_query = apply_sorting(base_query, SORTABLE_COLUMNS, 'key', :asc)
      @recurring_jobs = paginate(sorted_query)

      render_page('Recurring Jobs', SolidQueueMonitor::RecurringJobsPresenter.new(@recurring_jobs[:records],
                                                                                  current_page: @recurring_jobs[:current_page],
                                                                                  total_pages: @recurring_jobs[:total_pages],
                                                                                  filters: filter_params,
                                                                                  sort: sort_params).render)
    end
  end
end
