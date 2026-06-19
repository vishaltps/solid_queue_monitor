# frozen_string_literal: true

SolidQueueMonitor.setup do |config|
  # Enable or disable authentication
  # When disabled, no authentication is required to access the monitor
  config.authentication_enabled = false

  # Set the username for HTTP Basic Authentication (only used if authentication is enabled)
  # config.username = 'admin'
  # config.username = ENV['SOLID_QUEUE_MONITOR_USERNAME']
  # config.username = -> { Rails.application.credentials.dig(:solid_queue_monitor, :username) }

  # Set the password for HTTP Basic Authentication (only used if authentication is enabled)
  # config.password = 'password'
  # config.password = ENV['SOLID_QUEUE_MONITOR_PASSWORD']
  # config.password = -> { Rails.application.credentials.dig(:solid_queue_monitor, :password) }

  # Number of jobs to display per page
  # config.jobs_per_page = 25

  # Auto-refresh settings
  # Enable or disable auto-refresh globally (users can still toggle it in the UI)
  # config.auto_refresh_enabled = true

  # Auto-refresh interval in seconds (default: 30)
  # config.auto_refresh_interval = 30

  # Disable the chart on the overview page to skip chart queries entirely.
  # config.show_chart = true

  # Enable CSRF protection for the dashboard's destructive POST actions.
  # Disabled by default for backward compatibility. Requires the host app to
  # have a session store (e.g. cookie_store) and the dashboard mounted on the
  # same origin. When enabled, all dashboard forms embed an authenticity token
  # and unverified POSTs are rejected.
  # config.csrf_protection_enabled = false
end
