# frozen_string_literal: true

FactoryBot.define do
  factory :solid_queue_job, class: 'SolidQueue::Job' do
    queue_name { 'default' }
    class_name { 'TestJob' }
    arguments { [{ test: true }.to_json] }
    priority { 0 }
    scheduled_at { nil }
    finished_at { nil }
    created_at { Time.current }
    updated_at { Time.current }

    trait :finished do
      finished_at { Time.current }
    end

    trait :scheduled do
      scheduled_at { 1.hour.from_now }

      after(:create) do |job|
        create(:solid_queue_scheduled_execution, job: job)
      end
    end

    trait :ready do
      after(:create) do |job|
        create(:solid_queue_ready_execution, job: job)
      end
    end

    trait :failed do
      after(:create) do |job|
        create(:solid_queue_failed_execution, job: job)
      end
    end

    trait :in_progress do
      after(:create) do |job|
        create(:solid_queue_execution, job: job)
      end
    end
  end

  factory :solid_queue_ready_execution, class: 'SolidQueue::ReadyExecution' do
    association :job, factory: :solid_queue_job
    queue_name { job.queue_name }
    priority { job.priority }
    created_at { Time.current }
  end

  factory :solid_queue_scheduled_execution, class: 'SolidQueue::ScheduledExecution' do
    association :job, factory: :solid_queue_job
    scheduled_at { 1.hour.from_now }
    created_at { Time.current }
  end

  factory :solid_queue_failed_execution, class: 'SolidQueue::FailedExecution' do
    association :job, factory: :solid_queue_job
    error { "RuntimeError: Something went wrong\n  at line 1\n  at line 2" }
    created_at { Time.current }
  end

  factory :solid_queue_execution, class: 'SolidQueue::Execution' do
    association :job, factory: :solid_queue_job
    queue_name { job.queue_name }
    process_id { "pid-#{SecureRandom.hex(4)}" }
    created_at { Time.current }
  end

  factory :solid_queue_recurring_execution, class: 'SolidQueue::RecurringExecution' do
    class_name { 'RecurringJob' }
    arguments { [{ recurring: true }.to_json] }
    sequence(:schedule_name) { |n| "schedule_#{n}" }
    last_run_at { 1.day.ago }
    scheduled_at { 1.day.from_now }
    created_at { Time.current }
    updated_at { Time.current }

    # Add dynamic handling for schedule if provided
    transient do
      schedule { nil }
      queue_name { nil }
      job_class { nil }
    end

    # Override class_name if job_class is provided
    after(:build) do |recurring_execution, evaluator|
      recurring_execution.class_name = evaluator.job_class if evaluator.job_class

      # Add schedule attribute if model has it
      recurring_execution.schedule = evaluator.schedule if evaluator.schedule && recurring_execution.class.column_names.include?('schedule')

      # Add queue_name attribute if model has it
      recurring_execution.queue_name = evaluator.queue_name if evaluator.queue_name && recurring_execution.class.column_names.include?('queue_name')
    end
  end
end
