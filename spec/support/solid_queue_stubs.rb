# frozen_string_literal: true

# Define SolidQueue models for testing (if not already defined by solid_queue gem)
# This file should be loaded after ActiveRecord is available but before
# any code tries to use SolidQueue models

unless defined?(SolidQueue)
  module SolidQueue
    class ApplicationRecord < ActiveRecord::Base
      self.abstract_class = true
    end

    class Job < ApplicationRecord
      self.table_name = 'solid_queue_jobs'

      has_one :ready_execution, dependent: :destroy
      has_one :scheduled_execution, dependent: :destroy
      has_one :failed_execution, dependent: :destroy
      has_one :claimed_execution, dependent: :destroy

      def failed?
        failed_execution.present?
      end
    end

    class ReadyExecution < ApplicationRecord
      self.table_name = 'solid_queue_ready_executions'
      belongs_to :job
    end

    class ScheduledExecution < ApplicationRecord
      self.table_name = 'solid_queue_scheduled_executions'
      belongs_to :job
    end

    class FailedExecution < ApplicationRecord
      self.table_name = 'solid_queue_failed_executions'
      belongs_to :job

      def retry
        # Stub implementation for testing
        job&.update(finished_at: nil)
        destroy
        true
      end

      def discard
        job&.update(finished_at: Time.current)
        destroy
        true
      end
    end

    class ClaimedExecution < ApplicationRecord
      self.table_name = 'solid_queue_claimed_executions'
      belongs_to :job
    end

    class Pause < ApplicationRecord
      self.table_name = 'solid_queue_pauses'
    end

    class RecurringExecution < ApplicationRecord
      self.table_name = 'solid_queue_recurring_executions'
    end

    class RecurringTask < ApplicationRecord
      self.table_name = 'solid_queue_recurring_tasks'

      # Mirrors SolidQueue::RecurringTask#enqueue for the test double.
      # The real model records one execution per task and timestamp, then
      # places the job on the ready queue immediately.
      def enqueue(at:)
        return false if RecurringExecution.exists?(task_key: key, run_at: at)

        job = Job.create!(
          queue_name: queue_name.presence || 'default',
          class_name: class_name.presence || 'SolidQueue::RecurringJob',
          arguments: arguments,
          priority: priority || 0,
          active_job_id: SecureRandom.uuid
        )
        ReadyExecution.create!(job: job, queue_name: job.queue_name, priority: job.priority)
        RecurringExecution.create!(job_id: job.id, task_key: key, run_at: at)

        Struct.new(:successfully_enqueued?).new(true)
      end
    end

    class Process < ApplicationRecord
      self.table_name = 'solid_queue_processes'
    end

    class Queue
      attr_reader :name

      def initialize(name)
        @name = name
      end

      def paused?
        Pause.exists?(queue_name: @name)
      end

      def pause
        Pause.find_or_create_by(queue_name: @name)
      end

      def resume
        Pause.where(queue_name: @name).destroy_all
      end
    end
  end
end
