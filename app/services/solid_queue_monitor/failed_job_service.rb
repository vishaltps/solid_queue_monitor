module SolidQueueMonitor
  class FailedJobService
    def retry_job(failed_execution_id)
      failed_execution = SolidQueue::FailedExecution.find_by(id: failed_execution_id)
      return { success: false, message: "Failed job not found" } unless failed_execution
      
      job = failed_execution.job
      return { success: false, message: "Associated job not found" } unless job
      
      ActiveRecord::Base.transaction do
        # Create a ready execution for the job
        SolidQueue::ReadyExecution.create!(
          job_id: job.id,
          queue_name: get_queue_name(failed_execution, job),
          priority: job.priority
        )
        
        # Delete the failed execution
        failed_execution.destroy!
      end
      
      { success: true, message: "Job moved to ready queue for retry" }
    end
    
    def discard_job(failed_execution_id)
      failed_execution = SolidQueue::FailedExecution.find_by(id: failed_execution_id)
      return { success: false, message: "Failed job not found" } unless failed_execution
      
      job = failed_execution.job
      return { success: false, message: "Associated job not found" } unless job
      
      ActiveRecord::Base.transaction do
        # Mark the job as finished
        job.update!(finished_at: Time.current)
        
        # Delete the failed execution
        failed_execution.destroy!
      end
      
      { success: true, message: "Job has been discarded" }
    end
    
    def retry_all(job_ids)
      return { success: false, message: "No jobs selected" } if job_ids.blank?
      
      success_count = 0
      failed_count = 0
      
      job_ids.each do |id|
        result = retry_job(id)
        if result[:success]
          success_count += 1
        else
          failed_count += 1
        end
      end
      
      if success_count > 0 && failed_count == 0
        { success: true, message: "All selected jobs have been queued for retry" }
      elsif success_count > 0 && failed_count > 0
        { success: true, message: "#{success_count} jobs queued for retry, #{failed_count} failed" }
      else
        { success: false, message: "Failed to retry jobs" }
      end
    end
    
    def discard_all(job_ids)
      return { success: false, message: "No jobs selected" } if job_ids.blank?
      
      success_count = 0
      failed_count = 0
      
      job_ids.each do |id|
        result = discard_job(id)
        if result[:success]
          success_count += 1
        else
          failed_count += 1
        end
      end
      
      if success_count > 0 && failed_count == 0
        { success: true, message: "All selected jobs have been discarded" }
      elsif success_count > 0 && failed_count > 0
        { success: true, message: "#{success_count} jobs discarded, #{failed_count} failed" }
      else
        { success: false, message: "Failed to discard jobs" }
      end
    end
    
    private
    
    def get_queue_name(failed_execution, job)
      # Try to get queue_name from failed_execution if the method exists
      if failed_execution.respond_to?(:queue_name) && failed_execution.queue_name.present?
        failed_execution.queue_name
      else
        # Fall back to job's queue_name
        job.queue_name
      end
    end
  end
end 