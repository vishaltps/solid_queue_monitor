module TestHelpers
  def create_test_job(status: :pending)
    job = SolidQueue::Job.create!(
      class_name: 'TestJob',
      queue_name: 'default',
      arguments: ['test']
    )

    case status
    when :scheduled
      SolidQueue::ScheduledExecution.create!(
        job: job,
        queue_name: 'default',
        scheduled_at: 1.hour.from_now
      )
    when :failed
      SolidQueue::FailedExecution.create!(
        job: job,
        error: {
          'exception_class' => 'StandardError',
          'message' => 'Test error'
        }
      )
    end

    job
  end

  def create_recurring_job
    SolidQueue::RecurringTask.create!(
      key: 'test_recurring',
      class_name: 'TestJob',
      schedule: '0 * * * *',
      queue_name: 'default'
    )
  end
end

RSpec.configure do |config|
  config.include TestHelpers
end