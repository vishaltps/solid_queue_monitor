# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'
require 'solid_queue'

# Require the gems listed in Gemfile
Bundler.require(*Rails.groups)
require 'solid_queue_monitor'

module Dummy
  class Application < Rails::Application
    # Handle different ways to set config.load_defaults based on Rails version
    rails_version = Rails::VERSION::MAJOR
    rails_version_minor = Rails::VERSION::MINOR

    if rails_version >= 8
      config.load_defaults 8.0
    elsif rails_version == 7 && rails_version_minor >= 1
      config.load_defaults 7.1
    elsif rails_version == 7
      config.load_defaults 7.0
    else
      config.load_defaults Rails::VERSION::STRING.to_f
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Use SolidQueue as the ActiveJob queue adapter
    config.active_job.queue_adapter = :solid_queue

    # Don't generate system test files.
    config.generators.system_tests = nil

    # Set eager loading to false in test environment
    config.eager_load = false if Rails.env.test?

    # Tell Rails to use database.yml or DATABASE_URL
    config.paths['config/database'] = [] if ENV['DATABASE_URL'].present?
  end
end
