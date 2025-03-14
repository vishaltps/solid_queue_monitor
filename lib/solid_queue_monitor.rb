# frozen_string_literal: true

require_relative "solid_queue_monitor/version"
require_relative "solid_queue_monitor/engine"

module SolidQueueMonitor
  class Error < StandardError; end
  # Configuration options
  mattr_accessor :username, default: 'admin'
  mattr_accessor :password, default: 'password'
  mattr_accessor :jobs_per_page, default: 25

  def self.setup
    yield self
  end
end
