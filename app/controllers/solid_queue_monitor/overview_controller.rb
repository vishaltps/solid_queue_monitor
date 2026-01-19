# frozen_string_literal: true

module SolidQueueMonitor
  class OverviewController < BaseController
    def index
      @stats = SolidQueueMonitor::StatsCalculator.calculate
      @chart_data = SolidQueueMonitor::ChartDataService.new(time_range: time_range_param).calculate

      recent_jobs_query = SolidQueue::Job.order(created_at: :desc).limit(100)
      @recent_jobs = paginate(filter_jobs(recent_jobs_query))

      preload_job_statuses(@recent_jobs[:records])

      render_page('Overview', generate_overview_content)
    end

    def chart_data
      chart_data = SolidQueueMonitor::ChartDataService.new(time_range: time_range_param).calculate
      render json: chart_data
    end

    private

    def time_range_param
      params[:time_range] || ChartDataService::DEFAULT_TIME_RANGE
    end

    def generate_overview_content
      SolidQueueMonitor::StatsPresenter.new(@stats).render +
        SolidQueueMonitor::ChartPresenter.new(@chart_data).render +
        SolidQueueMonitor::JobsPresenter.new(@recent_jobs[:records],
                                             current_page: @recent_jobs[:current_page],
                                             total_pages: @recent_jobs[:total_pages],
                                             filters: filter_params).render
    end
  end
end
