module SolidQueueMonitor
  class StatsCalculator
    def self.calculate
      {
        total_jobs: SolidQueue::Job.count,
        unique_queues: SolidQueue::Job.distinct.count(:queue_name),
        scheduled: SolidQueue::ScheduledExecution.count,
        ready: SolidQueue::ReadyExecution.count,
        failed: SolidQueue::FailedExecution.count,
        completed: SolidQueue::Job.where.not(finished_at: nil).count,
        recurring: SolidQueue::RecurringTask.count
      }
    end
  end
end