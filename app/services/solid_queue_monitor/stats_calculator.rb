# frozen_string_literal: true

module SolidQueueMonitor
  class StatsCalculator
    def self.calculate
      scheduled   = SolidQueue::ScheduledExecution.count
      ready       = SolidQueue::ReadyExecution.count
      blocked     = SolidQueue::BlockedExecution.count
      failed      = SolidQueue::FailedExecution.count
      in_progress = SolidQueue::ClaimedExecution.count
      recurring   = SolidQueue::RecurringTask.count

      {
        # Jobs waiting to run or running. Failed jobs are left out: they only
        # run again after a retry, and have their own card.
        active_jobs: ready + scheduled + in_progress + blocked,
        scheduled: scheduled,
        ready: ready,
        blocked: blocked,
        failed: failed,
        in_progress: in_progress,
        recurring: recurring
      }
    end
  end
end
