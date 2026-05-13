# frozen_string_literal: true

module SolidQueueMonitor
  class RecurringJobsController < BaseController
    SORTABLE_COLUMNS = %w[key class_name queue_name priority].freeze

    def index
      base_query = filter_recurring_jobs(SolidQueue::RecurringTask.all)
      sorted_query = apply_sorting(base_query, SORTABLE_COLUMNS, 'key', :asc)
      @recurring_jobs = paginate(sorted_query)
      @filters = filter_params
      @sort = sort_params
      @action_path = recurring_jobs_path
    end
  end
end
