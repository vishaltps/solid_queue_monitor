# frozen_string_literal: true

module SolidQueueMonitor
  class ReadyJobsController < BaseController
    SORTABLE_COLUMNS = %w[class_name queue_name priority created_at].freeze

    def index
      base_query = SolidQueue::ReadyExecution.includes(:job)
      sorted_query = apply_execution_sorting(filter_ready_jobs(base_query), SORTABLE_COLUMNS, 'created_at', :desc)
      @ready_jobs = paginate(sorted_query)

      render_page('Ready Jobs', SolidQueueMonitor::ReadyJobsPresenter.new(@ready_jobs[:records],
                                                                          current_page: @ready_jobs[:current_page],
                                                                          total_pages: @ready_jobs[:total_pages],
                                                                          filters: filter_params,
                                                                          sort: sort_params).render)
    end
  end
end
