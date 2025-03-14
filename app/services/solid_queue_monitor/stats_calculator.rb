module SolidQueueMonitor
  class StatsCalculator
    def self.calculate
      {
        total_jobs: SolidQueue::Job.count,
        queues: SolidQueue::Job.distinct.count(:queue_name),
        scheduled: SolidQueue::ScheduledExecution.count,
        ready: SolidQueue::ReadyExecution.count,
        failed: SolidQueue::FailedExecution.count,
        recurring: SolidQueue::RecurringTask.count
      }
    end
  end
end