# frozen_string_literal: true

require_relative "solid_queue_monitor/version"
require_relative "solid_queue_monitor/engine"

module SolidQueueMonitor
  class Error < StandardError; end
  # Configuration options
  mattr_accessor :username
  @@username = 'admin'

  mattr_accessor :password
  @@password = 'password'

  mattr_accessor :jobs_per_page
  @@jobs_per_page = 25

  mattr_accessor :authentication_enabled
  @@authentication_enabled = false

  def self.setup
    yield self
  end
end
