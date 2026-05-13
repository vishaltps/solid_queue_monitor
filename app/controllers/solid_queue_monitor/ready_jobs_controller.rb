# frozen_string_literal: true

module SolidQueueMonitor
  class ReadyJobsController < BaseController
    SORTABLE_COLUMNS = %w[class_name queue_name priority created_at].freeze

    def index
      base_query = SolidQueue::ReadyExecution.includes(:job)
      sorted_query = apply_execution_sorting(filter_ready_jobs(base_query), SORTABLE_COLUMNS, 'created_at', :desc)
      @ready_jobs = paginate(sorted_query)
      @filters = filter_params
      @sort = sort_params
      @action_path = ready_jobs_path
    end
  end
end
