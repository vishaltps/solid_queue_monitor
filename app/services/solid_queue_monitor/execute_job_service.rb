# frozen_string_literal: true

module SolidQueueMonitor
  class ExecuteJobService
    def call(id)
      execution = SolidQueue::ScheduledExecution.find(id)
      move_to_ready_queue(execution)
    end

    def execute_many(ids)
      SolidQueue::ScheduledExecution.where(id: ids).find_each do |execution|
        move_to_ready_queue(execution)
      end
    end

    private

    def move_to_ready_queue(execution)
      ActiveRecord::Base.transaction do
        SolidQueue::ReadyExecution.create!(
          job: execution.job,
          queue_name: execution.queue_name,
          priority: execution.priority
        )

        execution.destroy
      end
    end
  end
end
