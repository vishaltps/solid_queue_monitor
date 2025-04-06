# frozen_string_literal: true

module SolidQueueMonitor
  class RecurringJobsController < BaseController
    def index
      base_query = filter_recurring_jobs(SolidQueue::RecurringTask.order(:key))
      @recurring_jobs = paginate(base_query)

      render_page('Recurring Jobs', SolidQueueMonitor::RecurringJobsPresenter.new(@recurring_jobs[:records],
                                                                                  current_page: @recurring_jobs[:current_page],
                                                                                  total_pages: @recurring_jobs[:total_pages],
                                                                                  filters: filter_params).render)
    end
  end
end
