# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'

# Load the dummy Rails application first
require File.expand_path('dummy/config/environment', __dir__)

# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?

require 'rspec/rails'
require 'factory_bot_rails'

# Set up the test database
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)

# Load the schema
ActiveRecord::Schema.verbose = false
ActiveRecord::Schema.define(version: 1) do
  create_table :solid_queue_jobs, force: true do |t|
    t.string :queue_name, null: false
    t.string :class_name, null: false
    t.text :arguments
    t.integer :priority, default: 0, null: false
    t.string :active_job_id
    t.datetime :scheduled_at
    t.datetime :finished_at
    t.string :concurrency_key
    t.timestamps
  end

  create_table :solid_queue_ready_executions, force: true do |t|
    t.integer :job_id, null: false
    t.string :queue_name, null: false
    t.integer :priority, default: 0, null: false
    t.datetime :created_at, null: false
  end

  create_table :solid_queue_scheduled_executions, force: true do |t|
    t.integer :job_id, null: false
    t.string :queue_name, null: false
    t.integer :priority, default: 0, null: false
    t.datetime :scheduled_at, null: false
    t.datetime :created_at, null: false
  end

  create_table :solid_queue_failed_executions, force: true do |t|
    t.integer :job_id, null: false
    t.text :error
    t.datetime :created_at, null: false
  end

  create_table :solid_queue_claimed_executions, force: true do |t|
    t.integer :job_id, null: false
    t.bigint :process_id
    t.datetime :created_at, null: false
  end

  create_table :solid_queue_pauses, force: true do |t|
    t.string :queue_name, null: false
    t.datetime :created_at, null: false
  end

  create_table :solid_queue_recurring_tasks, force: true do |t|
    t.string :key, null: false
    t.string :schedule, null: false
    t.string :command
    t.string :class_name
    t.text :arguments
    t.string :queue_name
    t.integer :priority
    t.boolean :static, default: false, null: false
    t.text :description
    t.timestamps
  end

  create_table :solid_queue_processes, force: true do |t|
    t.string :kind, null: false
    t.datetime :last_heartbeat_at, null: false
    t.bigint :supervisor_id
    t.integer :pid, null: false
    t.string :hostname
    t.text :metadata
    t.datetime :created_at, null: false
  end

  add_index :solid_queue_pauses, :queue_name, unique: true
end

# Define SolidQueue models for testing (if not already defined by solid_queue gem)
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
        job.update(finished_at: nil) if job
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

    class RecurringTask < ApplicationRecord
      self.table_name = 'solid_queue_recurring_tasks'
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

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!

  # Configure RSpec to find spec files in the correct location
  config.pattern = 'spec/**/*_spec.rb'

  # Use transactional fixtures
  config.use_transactional_fixtures = true

  # Filter lines from Rails gems in backtraces
  config.filter_rails_from_backtrace!

  # Include FactoryBot methods
  config.include FactoryBot::Syntax::Methods

  # Set up engine routes for controller specs
  config.before(:each, type: :controller) do
    @routes = SolidQueueMonitor::Engine.routes
  end
end
