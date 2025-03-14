module SolidQueueMonitor
  class StatusCalculator
    def initialize(job)
      @job = job
    end

    def calculate
      return 'completed' if @job.finished_at.present?
      return 'failed' if SolidQueue::FailedExecution.exists?(job_id: @job.id)
      return 'scheduled' if @job.scheduled_at&.future?
      'pending'
    end
  end
end