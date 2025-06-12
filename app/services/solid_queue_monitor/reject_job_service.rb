# frozen_string_literal: true

module SolidQueueMonitor
  class RejectJobService
    def call(id)
      execution = SolidQueue::ScheduledExecution.find(id)
      reject_job(execution)
    end

    def reject_many(ids)
      return { success: false, message: 'No jobs selected' } if ids.blank?

      success_count = 0
      failed_count = 0

      ids.each do |id|
        begin
          execution = SolidQueue::ScheduledExecution.find_by(id: id)
          if execution
            reject_job(execution)
            success_count += 1
          else
            failed_count += 1
          end
        rescue StandardError
          failed_count += 1
        end
      end

      if success_count.positive? && failed_count.zero?
        { success: true, message: 'All selected jobs have been rejected' }
      elsif success_count.positive? && failed_count.positive?
        { success: true, message: "#{success_count} jobs rejected, #{failed_count} failed" }
      else
        { success: false, message: 'Failed to reject jobs' }
      end
    end

    private

    def reject_job(execution)
      ActiveRecord::Base.transaction do
        # Mark the associated job as finished to indicate it was rejected
        execution.job.update!(finished_at: Time.current)

        # Remove the scheduled execution
        execution.destroy
      end
    end
  end
end