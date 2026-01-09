# frozen_string_literal: true

SolidQueueMonitor.setup do |config|
  # Enable or disable authentication
  # When disabled, no authentication is required to access the monitor
  config.authentication_enabled = false

  # Set the username for HTTP Basic Authentication (only used if authentication is enabled)
  # config.username = 'admin'

  # Set the password for HTTP Basic Authentication (only used if authentication is enabled)
  # config.password = 'password'

  # Number of jobs to display per page
  # config.jobs_per_page = 25

  # Auto-refresh settings
  # Enable or disable auto-refresh globally (users can still toggle it in the UI)
  # config.auto_refresh_enabled = true

  # Auto-refresh interval in seconds (default: 30)
  # config.auto_refresh_interval = 30
end
