# frozen_string_literal: true

module SolidQueueMonitor
  class StatsCalculator
    def self.calculate
      scheduled   = SolidQueue::ScheduledExecution.count
      ready       = SolidQueue::ReadyExecution.count
      failed      = SolidQueue::FailedExecution.count
      in_progress = SolidQueue::ClaimedExecution.count
      recurring   = SolidQueue::RecurringTask.count

      {
        active_jobs: ready + scheduled + in_progress + failed,
        scheduled:   scheduled,
        ready:       ready,
        failed:      failed,
        in_progress: in_progress,
        recurring:   recurring
      }
    end
  end
end
