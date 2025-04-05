# frozen_string_literal: true

require_relative 'boot'

require 'rails'
require 'active_model/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'solid_queue'
require 'solid_queue_monitor'

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f

    # For Rails 7+
    config.active_job.queue_adapter = :solid_queue

    # Prevent deprecation warnings
    config.active_support.deprecation = :log
    config.eager_load = false

    # Database configuration
    config.active_record.sqlite3.represent_boolean_as_integer = true
  end
end
