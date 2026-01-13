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

# Load the SolidQueue model stubs (after schema is created)
require_relative 'support/solid_queue_stubs'

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!

  # Use transactional fixtures
  config.use_transactional_fixtures = true

  # Filter lines from Rails gems in backtraces
  config.filter_rails_from_backtrace!

  # Include FactoryBot methods
  config.include FactoryBot::Syntax::Methods

  # Include engine routes for request specs
  config.include SolidQueueMonitor::Engine.routes.url_helpers, type: :request

  # For request specs, use a rack app that includes session middleware
  # This ensures session[:flash_message] works in tests
  config.before(:each, type: :request) do
    def app
      @app ||= Rack::Builder.new do
        use ActionDispatch::Session::CookieStore,
            key: '_test_session',
            secret: 'a' * 64  # 64 byte secret for testing
        run SolidQueueMonitor::Engine
      end.to_app
    end
  end
end
