# frozen_string_literal: true

module SolidQueueMonitor
  class ScheduledJobsController < BaseController
    def index
      base_query = SolidQueue::ScheduledExecution.includes(:job).order(scheduled_at: :asc)
      @scheduled_jobs = paginate(filter_scheduled_jobs(base_query))

      render_page('Scheduled Jobs', SolidQueueMonitor::ScheduledJobsPresenter.new(@scheduled_jobs[:records],
                                                                                  current_page: @scheduled_jobs[:current_page],
                                                                                  total_pages: @scheduled_jobs[:total_pages],
                                                                                  filters: filter_params).render)
    end

    def create
      if params[:job_ids].present?
        SolidQueueMonitor::ExecuteJobService.new.execute_many(params[:job_ids])
        set_flash_message('Selected jobs moved to ready queue', 'success')
      else
        set_flash_message('No jobs selected', 'error')
      end
      redirect_to scheduled_jobs_path
    end

    def execute
      SolidQueueMonitor::ExecuteJobService.new.call(params[:id])
      set_flash_message('Job moved to ready queue', 'success')
      redirect_to params[:redirect_to] || scheduled_jobs_path
    rescue ActiveRecord::RecordNotFound
      set_flash_message('Job not found', 'error')
      redirect_to scheduled_jobs_path
    end

    def reject_all
      result = SolidQueueMonitor::RejectJobService.new.reject_many(params[:job_ids])

      if result[:success]
        set_flash_message(result[:message], 'success')
      else
        set_flash_message(result[:message], 'error')
      end
      redirect_to scheduled_jobs_path
    end
  end
end
