# frozen_string_literal: true

require_relative 'solid_queue_monitor/version'
require_relative 'solid_queue_monitor/engine'

module SolidQueueMonitor
  class Error < StandardError; end
  class << self
    attr_writer :username, :password
    attr_accessor :jobs_per_page, :authentication_enabled,
                  :auto_refresh_enabled, :auto_refresh_interval, :show_chart

    def username
      resolve_value(@username)
    end

    def password
      resolve_value(@password)
    end

    private

    def resolve_value(value)
      value.respond_to?(:call) ? value.call : value
    end
  end

  @username = 'admin'
  @password = 'password'
  @jobs_per_page = 25
  @authentication_enabled = false
  @auto_refresh_enabled = true
  @auto_refresh_interval = 30 # seconds
  @show_chart = true

  def self.setup
    yield self
  end
end
