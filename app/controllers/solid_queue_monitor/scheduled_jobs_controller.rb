module SolidQueueMonitor
  class ScheduledJobsController < BaseController
    def index
      base_query = SolidQueue::ScheduledExecution.includes(:job).order(scheduled_at: :asc)
      @scheduled_jobs = paginate(filter_scheduled_jobs(base_query))
      
      render_page('Scheduled Jobs', SolidQueueMonitor::ScheduledJobsPresenter.new(@scheduled_jobs[:records],
        current_page: @scheduled_jobs[:current_page],
        total_pages: @scheduled_jobs[:total_pages],
        filters: filter_params
      ).render)
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
  end
end 