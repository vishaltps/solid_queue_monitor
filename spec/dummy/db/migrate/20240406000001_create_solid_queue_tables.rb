# frozen_string_literal: true

class CreateSolidQueueTables < ActiveRecord::Migration[7.1]
  def change
    create_table :solid_queue_jobs do |t|
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
      t.index %i[concurrency_key finished_at], name: 'index_solid_queue_jobs_on_concurrency_key', where: 'concurrency_key IS NOT NULL'
    end

    create_table :solid_queue_ready_executions do |t|
      t.references :job, null: false, foreign_key: { to_table: :solid_queue_jobs, on_delete: :cascade }
      t.string :queue_name, null: false
      t.integer :priority, default: 0, null: false
      t.datetime :created_at, null: false

      t.index %i[queue_name priority created_at], name: 'index_solid_queue_ready_executions_for_polling'
    end

    create_table :solid_queue_scheduled_executions do |t|
      t.references :job, null: false, foreign_key: { to_table: :solid_queue_jobs, on_delete: :cascade }
      t.datetime :scheduled_at, null: false
      t.datetime :created_at, null: false

      t.index :scheduled_at
    end

    create_table :solid_queue_failed_executions do |t|
      t.references :job, null: false, foreign_key: { to_table: :solid_queue_jobs, on_delete: :cascade }
      t.text :error
      t.datetime :created_at, null: false

      t.index :created_at
    end

    create_table :solid_queue_pauses do |t|
      t.string :queue_name, null: false
      t.datetime :created_at, null: false

      t.index :queue_name, unique: true
    end

    create_table :solid_queue_semaphores do |t|
      t.string :key, null: false
      t.integer :value, default: 1, null: false
      t.datetime :expires_at, null: false
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false

      t.index %i[key value], name: 'index_solid_queue_semaphores_on_key_and_value'
      t.index [:expires_at], name: 'index_solid_queue_semaphores_on_expires_at'
    end

    create_table :solid_queue_claimed_executions do |t|
      t.references :job, null: false, foreign_key: { to_table: :solid_queue_jobs, on_delete: :cascade }
      t.bigint :process_id
      t.datetime :created_at, null: false

      t.index [:process_id]
    end

    create_table :solid_queue_blocked_executions do |t|
      t.references :job, null: false, foreign_key: { to_table: :solid_queue_jobs, on_delete: :cascade }
      t.string :concurrency_key, null: false
      t.datetime :expires_at, null: false
      t.datetime :created_at, null: false

      t.index %i[concurrency_key job_id], name: 'index_solid_queue_blocked_executions_on_concurrency_key_and_job_id'
      t.index [:expires_at], name: 'index_solid_queue_blocked_executions_on_expires_at'
    end

    create_table :solid_queue_recurring_executions do |t|
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

    create_table :solid_queue_processes do |t|
      t.string :kind, null: false
      t.datetime :last_heartbeat_at, null: false
      t.bigint :supervisor_id
      t.integer :pid, null: false
      t.string :hostname, null: false
      t.text :metadata
      t.datetime :created_at, null: false

      t.index [:last_heartbeat_at]
      t.index [:supervisor_id]
    end

    # For compatibility with Solid Queue versions <0.2
    create_table :solid_queue_executions do |t|
      t.references :job, null: false, foreign_key: { to_table: :solid_queue_jobs, on_delete: :cascade }
      t.string :queue_name, null: false
      t.string :process_id
      t.datetime :created_at, null: false

      t.index %i[process_id queue_name created_at], name: 'index_solid_queue_executions_for_polling'
    end
  end
end
