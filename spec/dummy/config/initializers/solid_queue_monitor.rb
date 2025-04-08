# frozen_string_literal: true

SolidQueueMonitor.setup do |config|
  # Enable or disable authentication
  config.authentication_enabled = false

  # Set the username for HTTP Basic Authentication
  config.username = 'admin'

  # Set the password for HTTP Basic Authentication
  config.password = 'password'

  # Number of jobs to display per page
  config.jobs_per_page = 10
end
