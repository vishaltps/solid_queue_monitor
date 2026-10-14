# frozen_string_literal: true

module SolidQueueMonitor
  class EnqueueRecurringTaskService
    class << self
      def call(id)
        task = SolidQueue::RecurringTask.find(id)
        enqueued_job = task.enqueue(at: Time.current)

        if enqueued?(enqueued_job)
          { success: true, message: "Recurring task '#{task.key}' has been queued to run now" }
        else
          { success: false, message: "Could not enqueue recurring task '#{task.key}'. It may already be queued for this time" }
        end
      rescue ActiveRecord::RecordNotFound
        { success: false, message: 'Recurring task not found' }
      rescue StandardError => e
        { success: false, message: "Failed to enqueue recurring task: #{e.message}" }
      end

      private

      def enqueued?(enqueued_job)
        enqueued_job.respond_to?(:successfully_enqueued?) && enqueued_job.successfully_enqueued?
      end
    end
  end
end
