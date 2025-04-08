# frozen_string_literal: true

# Clean up existing data
SolidQueue::Job.destroy_all
SolidQueue::ReadyExecution.destroy_all
SolidQueue::ScheduledExecution.destroy_all
SolidQueue::FailedExecution.destroy_all
SolidQueue::Execution.destroy_all
SolidQueue::RecurringExecution.destroy_all

# Create jobs in various states
puts 'Creating test SolidQueue jobs...'

# Create some regular jobs
10.times do |i|
  job = SolidQueue::Job.create!(
    queue_name: %w[default mailers active_storage].sample,
    class_name: %w[TestJob EmailJob ProcessingJob ReportJob].sample,
    arguments: [{ id: i, action: 'process' }.to_json],
    priority: rand(10),
    created_at: Time.current - rand(1..30).minutes
  )

  # Make some jobs ready
  if i % 3 == 0
    SolidQueue::ReadyExecution.create!(
      job: job,
      queue_name: job.queue_name,
      priority: job.priority,
      created_at: Time.current
    )
  end

  # Make some jobs scheduled
  if i % 3 == 1
    SolidQueue::ScheduledExecution.create!(
      job: job,
      scheduled_at: Time.current + rand(1..60).minutes,
      created_at: Time.current
    )
  end

  # Make some jobs failed
  if i % 5 == 0
    SolidQueue::FailedExecution.create!(
      job: job,
      error: "RuntimeError: Something went wrong\n#{caller.join("\n")[0..300]}",
      created_at: Time.current - rand(1..10).minutes
    )
  end

  # Make some jobs in progress
  next unless i % 7 == 0

  SolidQueue::Execution.create!(
    job: job,
    queue_name: job.queue_name,
    process_id: "test-worker-#{rand(1..5)}",
    created_at: Time.current - rand(1..5).minutes
  )
end

# Create some recurring jobs
%w[DailyReport HourlySync WeeklyCleanup].each do |job_name|
  SolidQueue::RecurringExecution.create!(
    class_name: "#{job_name}Job",
    arguments: [{ recurring: true }.to_json],
    schedule_name: job_name.underscore,
    last_run_at: Time.current - rand(1..24).hours,
    scheduled_at: Time.current + rand(1..24).hours,
    created_at: 1.day.ago
  )
end

puts "Created #{SolidQueue::Job.count} jobs"
puts "Ready: #{SolidQueue::ReadyExecution.count}"
puts "Scheduled: #{SolidQueue::ScheduledExecution.count}"
puts "Failed: #{SolidQueue::FailedExecution.count}"
puts "In Progress: #{SolidQueue::Execution.count}"
puts "Recurring: #{SolidQueue::RecurringExecution.count}"
