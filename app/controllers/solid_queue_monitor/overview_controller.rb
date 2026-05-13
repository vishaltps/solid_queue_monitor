# frozen_string_literal: true

module SolidQueueMonitor
  class OverviewController < BaseController
    SORTABLE_COLUMNS = %w[class_name queue_name created_at].freeze

    def index
      @stats = SolidQueueMonitor::StatsCalculator.calculate
      @chart_data = SolidQueueMonitor.show_chart ? SolidQueueMonitor::ChartDataService.new(time_range: time_range_param).calculate : nil
      @time_range = time_range_param

      recent_jobs_query = SolidQueue::Job.limit(100)
      sorted_query = apply_sorting(filter_jobs(recent_jobs_query), SORTABLE_COLUMNS, 'created_at', :desc)
      @recent_jobs = paginate(sorted_query)
      @filters = filter_params
      @sort = sort_params

      preload_job_statuses(@recent_jobs[:records])
    end

    def chart_data
      chart_data = SolidQueueMonitor::ChartDataService.new(time_range: time_range_param).calculate
      render json: chart_data
    end

    private

    def time_range_param
      params[:time_range] || ChartDataService::DEFAULT_TIME_RANGE
    end
  end
end
