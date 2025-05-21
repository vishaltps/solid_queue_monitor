# frozen_string_literal: true

SolidQueueMonitor.setup do |config|
  config.username = 'admin'     # Change this in your application
  config.password = 'password'  # Change this in your application
  config.jobs_per_page = 25
  config.auto_refresh_enabled = true   # Enable/disable auto-refresh for stats
  config.auto_refresh_interval = 5000 # Interval in milliseconds
end
