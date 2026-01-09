# frozen_string_literal: true

require_relative 'solid_queue_monitor/version'
require_relative 'solid_queue_monitor/engine'

module SolidQueueMonitor
  class Error < StandardError; end
  class << self
    attr_accessor :username, :password, :jobs_per_page, :authentication_enabled,
                  :auto_refresh_enabled, :auto_refresh_interval
  end

  @username = 'admin'
  @password = 'password'
  @jobs_per_page = 25
  @authentication_enabled = false
  @auto_refresh_enabled = true
  @auto_refresh_interval = 30 # seconds

  def self.setup
    yield self
  end
end
