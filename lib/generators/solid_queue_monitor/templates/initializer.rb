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
end