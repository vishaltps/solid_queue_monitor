# frozen_string_literal: true

module SolidQueueMonitor
  class ReadyJobsController < BaseController
    def index
      base_query = SolidQueue::ReadyExecution.includes(:job).order(created_at: :desc)
      @ready_jobs = paginate(filter_ready_jobs(base_query))

      render_page('Ready Jobs', SolidQueueMonitor::ReadyJobsPresenter.new(@ready_jobs[:records],
                                                                          current_page: @ready_jobs[:current_page],
                                                                          total_pages: @ready_jobs[:total_pages],
                                                                          filters: filter_params).render)
    end
  end
end
