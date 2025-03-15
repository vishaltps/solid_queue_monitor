module SolidQueueMonitor
  class StatusCalculator
    def initialize(job)
      @job = job
    end

    def calculate
      return 'completed' if @job.finished_at.present?
      return 'failed' if @job.failed?
      return 'scheduled' if @job.scheduled_at&.future?
      'pending'
    end
  end
end