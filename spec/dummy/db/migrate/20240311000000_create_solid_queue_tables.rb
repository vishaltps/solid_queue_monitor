class CreateSolidQueueTables < ActiveRecord::Migration[7.0]
  def change
    create_table :solid_queue_jobs do |t|
      t.string :queue_name, null: false
      t.string :class_name, null: false
      t.text :arguments
      t.datetime :scheduled_at
      t.datetime :finished_at
      t.timestamps
    end

    create_table :solid_queue_scheduled_executions do |t|
      t.references :job, null: false
      t.string :queue_name, null: false
      t.datetime :scheduled_at, null: false
      t.integer :priority, default: 0, null: false
      t.timestamps
    end

    create_table :solid_queue_ready_executions do |t|
      t.references :job, null: false
      t.string :queue_name, null: false
      t.integer :priority, default: 0, null: false
      t.timestamps
    end

    create_table :solid_queue_failed_executions do |t|
      t.references :job, null: false
      t.text :error
      t.timestamps
    end

    create_table :solid_queue_recurring_tasks do |t|
      t.string :key, null: false
      t.string :class_name, null: false
      t.string :queue_name, null: false
      t.string :schedule
      t.text :arguments
      t.timestamps
    end

    add_index :solid_queue_recurring_tasks, :key, unique: true
  end
end