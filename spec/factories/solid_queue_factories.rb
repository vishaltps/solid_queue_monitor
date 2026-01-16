# frozen_string_literal: true

FactoryBot.define do
  factory :solid_queue_job, class: 'SolidQueue::Job' do
    queue_name { 'default' }
    class_name { 'TestJob' }
    arguments { '[]' }
    priority { 0 }
    active_job_id { SecureRandom.uuid }
    scheduled_at { nil }
    finished_at { nil }
    concurrency_key { nil }

    trait :completed do
      finished_at { Time.current }
    end

    trait :scheduled do
      scheduled_at { 1.hour.from_now }
    end
  end

  factory :solid_queue_ready_execution, class: 'SolidQueue::ReadyExecution' do
    association :job, factory: :solid_queue_job
    queue_name { 'default' }
    priority { 0 }
  end

  factory :solid_queue_scheduled_execution, class: 'SolidQueue::ScheduledExecution' do
    association :job, factory: :solid_queue_job
    queue_name { 'default' }
    priority { 0 }
    scheduled_at { 1.hour.from_now }
  end

  factory :solid_queue_failed_execution, class: 'SolidQueue::FailedExecution' do
    association :job, factory: :solid_queue_job
    error { 'StandardError: Test error message' }
  end

  factory :solid_queue_claimed_execution, class: 'SolidQueue::ClaimedExecution' do
    association :job, factory: :solid_queue_job
    process_id { 1 }
  end

  factory :solid_queue_pause, class: 'SolidQueue::Pause' do
    queue_name { 'default' }
  end

  factory :solid_queue_recurring_task, class: 'SolidQueue::RecurringTask' do
    key { "task_#{SecureRandom.hex(4)}" }
    schedule { '0 * * * *' }
    command { nil }
    class_name { 'TestRecurringJob' }
    arguments { nil }
    queue_name { 'default' }
    priority { 0 }
    static { false }
    description { nil }
  end

  factory :solid_queue_process, class: 'SolidQueue::Process' do
    kind { 'Worker' }
    last_heartbeat_at { Time.current }
    supervisor_id { nil }
    pid { Process.pid }
    hostname { 'localhost' }
    metadata { nil }
  end
end
