# frozen_string_literal: true

module SolidQueueMonitor
  class JobsController < BaseController
    def show
      @job = SolidQueue::Job.find_by(id: params[:id])

      unless @job
        set_flash_message('Job not found.', 'error')
        redirect_to root_path
        return
      end

      job_data = load_job_data(@job)

      render_page("Job ##{@job.id}", SolidQueueMonitor::JobDetailsPresenter.new(
        @job,
        **job_data
      ).render)
    end

    private

    def load_job_data(job)
      {
        failed_execution: SolidQueue::FailedExecution.find_by(job_id: job.id),
        claimed_execution: load_claimed_execution(job),
        scheduled_execution: SolidQueue::ScheduledExecution.find_by(job_id: job.id),
        recent_executions: load_recent_executions(job),
        back_path: determine_back_path
      }
    end

    def load_claimed_execution(job)
      claimed = SolidQueue::ClaimedExecution.find_by(job_id: job.id)
      return nil unless claimed

      # Preload process info
      claimed.instance_variable_set(:@process, SolidQueue::Process.find_by(id: claimed.process_id))
      claimed
    end

    def load_recent_executions(job)
      SolidQueue::Job
        .where(class_name: job.class_name)
        .where.not(id: job.id)
        .order(created_at: :desc)
        .limit(10)
        .includes(:failed_execution, :claimed_execution, :ready_execution, :scheduled_execution)
    end

    def determine_back_path
      referer = request.referer
      return root_path unless referer

      # Extract path from referer
      uri = URI.parse(referer)
      path = uri.path

      # Return referer if it's within the engine
      if path.include?('/failed_jobs') || path.include?('/ready_jobs') ||
         path.include?('/scheduled_jobs') || path.include?('/in_progress_jobs') ||
         path.include?('/recurring_jobs')
        referer
      else
        root_path
      end
    rescue URI::InvalidURIError
      root_path
    end
  end
end
