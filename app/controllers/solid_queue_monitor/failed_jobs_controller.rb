module SolidQueueMonitor
  class FailedJobsController < BaseController
    def index
      base_query = SolidQueue::FailedExecution.includes(:job).order(created_at: :desc)
      @failed_jobs = paginate(filter_failed_jobs(base_query))
      
      render_page('Failed Jobs', SolidQueueMonitor::FailedJobsPresenter.new(@failed_jobs[:records],
        current_page: @failed_jobs[:current_page],
        total_pages: @failed_jobs[:total_pages],
        filters: filter_params
      ).render)
    end
    
    def retry
      id = params[:id]
      service = SolidQueueMonitor::FailedJobService.new
      
      if service.retry_job(id)
        set_flash_message("Job #{id} has been queued for retry.", 'success')
      else
        set_flash_message("Failed to retry job #{id}.", 'error')
      end
      redirect_to failed_jobs_path
    end
    
    def discard
      id = params[:id]
      service = SolidQueueMonitor::FailedJobService.new
      
      if service.discard_job(id)
        set_flash_message("Job #{id} has been discarded.", 'success')
      else
        set_flash_message("Failed to discard job #{id}.", 'error')
      end
      redirect_to failed_jobs_path
    end
    
    def retry_all
      result = SolidQueueMonitor::FailedJobService.new.retry_all(params[:job_ids])
      
      if result[:success]
        set_flash_message(result[:message], 'success')
      else
        set_flash_message(result[:message], 'error')
      end
      redirect_to failed_jobs_path
    end
    
    def discard_all
      result = SolidQueueMonitor::FailedJobService.new.discard_all(params[:job_ids])
      
      if result[:success]
        set_flash_message(result[:message], 'success')
      else
        set_flash_message(result[:message], 'error')
      end
      redirect_to failed_jobs_path
    end
  end
end 