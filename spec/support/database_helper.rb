# frozen_string_literal: true

require 'active_record'
require 'pg'

module DatabaseHelper
  def self.setup_database
    # Connect to the PostgreSQL server
    ActiveRecord::Base.establish_connection(
      adapter: 'postgresql',
      host: 'localhost',
      database: 'postgres',
      username: ENV['PG_USERNAME'] || 'postgres'
    )

    # Drop the test database if it exists
    begin
      conn = PG.connect(
        host: 'localhost',
        dbname: 'postgres',
        user: ENV['PG_USERNAME'] || 'postgres'
      )
      conn.exec('DROP DATABASE IF EXISTS solid_queue_monitor_test')

      # Create the test database
      conn.exec('CREATE DATABASE solid_queue_monitor_test')
      conn.close
    rescue StandardError => e
      puts "Error setting up database: #{e.message}"
      return false
    end

    # Connect to the test database
    ActiveRecord::Base.establish_connection(
      adapter: 'postgresql',
      host: 'localhost',
      database: 'solid_queue_monitor_test',
      username: ENV['PG_USERNAME'] || 'postgres'
    )

    # Create the solid_queue tables
    create_solid_queue_tables
  end

  def self.create_solid_queue_tables
    ActiveRecord::Schema.define do
      create_table :solid_queue_jobs, force: true do |t|
        t.string :queue_name, null: false
        t.string :class_name, null: false
        t.text :arguments
        t.integer :priority, default: 0, null: false
        t.datetime :scheduled_at
        t.datetime :finished_at
        t.string :concurrency_key
        t.datetime :created_at, null: false
        t.datetime :updated_at, null: false

        t.index %i[queue_name finished_at scheduled_at priority], name: 'index_solid_queue_jobs_for_filtering'
        t.index %i[concurrency_key finished_at], name: 'index_solid_queue_jobs_on_concurrency_key'
      end

      create_table :solid_queue_ready_executions, force: true do |t|
        t.references :job, null: false, foreign_key: { to_table: :solid_queue_jobs }
        t.string :queue_name, null: false
        t.integer :priority, default: 0, null: false
        t.datetime :created_at, null: false

        t.index %i[queue_name priority created_at], name: 'index_solid_queue_ready_executions_for_polling'
      end

      create_table :solid_queue_scheduled_executions, force: true do |t|
        t.references :job, null: false, foreign_key: { to_table: :solid_queue_jobs }
        t.datetime :scheduled_at, null: false
        t.datetime :created_at, null: false

        t.index :scheduled_at
      end

      create_table :solid_queue_failed_executions, force: true do |t|
        t.references :job, null: false, foreign_key: { to_table: :solid_queue_jobs }
        t.text :error
        t.datetime :created_at, null: false

        t.index :created_at
      end

      create_table :solid_queue_executions, force: true do |t|
        t.references :job, null: false, foreign_key: { to_table: :solid_queue_jobs }
        t.string :queue_name, null: false
        t.string :process_id
        t.datetime :created_at, null: false

        t.index %i[process_id queue_name created_at], name: 'index_solid_queue_executions_for_polling'
      end

      create_table :solid_queue_recurring_executions, force: true do |t|
        t.string :class_name, null: false
        t.text :arguments
        t.string :schedule_name, null: false
        t.datetime :last_run_at, null: false
        t.datetime :scheduled_at, null: false
        t.datetime :created_at, null: false
        t.datetime :updated_at, null: false

        t.index [:schedule_name], unique: true
        t.index [:scheduled_at]
      end
    end
  end

  def self.clear_database
    ActiveRecord::Base.connection.tables.each do |table|
      next if table == 'schema_migrations'

      ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{table} CASCADE")
    end
  end
end
