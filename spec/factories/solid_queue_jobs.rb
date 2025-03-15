FactoryBot.define do
  factory :solid_queue_job, class: 'SolidQueue::Job' do
    class_name { "TestJob" }
    queue_name { "default" }
    arguments { [{ "test" => "argument" }] }
    created_at { Time.current }
    finished_at { nil }
    
    trait :completed do
      finished_at { Time.current }
    end
  end
  
  factory :solid_queue_failed_execution, class: 'SolidQueue::FailedExecution' do
    association :job, factory: :solid_queue_job
    error { { "message" => "Test error message", "backtrace" => ["line 1", "line 2"] } }
    queue_name { "default" }
    created_at { Time.current }
  end
  
  factory :solid_queue_scheduled_execution, class: 'SolidQueue::ScheduledExecution' do
    association :job, factory: :solid_queue_job
    queue_name { "default" }
    scheduled_at { 1.hour.from_now }
    priority { 0 }
    created_at { Time.current }
  end
  
  factory :solid_queue_ready_execution, class: 'SolidQueue::ReadyExecution' do
    association :job, factory: :solid_queue_job
    queue_name { "default" }
    priority { 0 }
    created_at { Time.current }
  end
  
  factory :solid_queue_recurring_task, class: 'SolidQueue::RecurringTask' do
    sequence(:key) { |n| "recurring_task_#{n}" }
    class_name { "RecurringJob" }
    queue_name { "default" }
    schedule { "every 1h" }
    arguments { [] }
    priority { nil }
    static { true }
    description { "A recurring task for testing" }
    created_at { Time.current }
    updated_at { Time.current }
  end
end 