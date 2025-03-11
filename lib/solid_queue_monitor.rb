# frozen_string_literal: true

require_relative "solid_queue_monitor/version"

module SolidQueueMonitor
  class Error < StandardError; end
    # Configuration options
    mattr_accessor :username
    @@username = 'admin'
  
    mattr_accessor :password
    @@password = 'password123'
  
    mattr_accessor :jobs_per_page
    @@jobs_per_page = 50
  
    def self.setup
      yield self
    end  
end
