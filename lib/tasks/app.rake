namespace :app do
  desc "Setup the dummy app for testing"
  task :setup do
    require 'fileutils'
    
    # Create dummy app directories
    dummy_app_path = File.expand_path("../../spec/dummy", __FILE__)
    
    # Ensure directories exist
    %w[
      app/controllers
      app/models
      app/views
      config/environments
      config/initializers
      db
      lib
      log
    ].each do |dir|
      FileUtils.mkdir_p(File.join(dummy_app_path, dir))
    end
    
    # Create necessary files if they don't exist
    unless File.exist?(File.join(dummy_app_path, "config/boot.rb"))
      File.write(File.join(dummy_app_path, "config/boot.rb"), <<~RUBY)
        ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../../Gemfile', __dir__)
        require 'bundler/setup'
      RUBY
    end
    
    unless File.exist?(File.join(dummy_app_path, "config/application.rb"))
      File.write(File.join(dummy_app_path, "config/application.rb"), <<~RUBY)
        require_relative "boot"
        
        require "rails"
        require "active_model/railtie"
        require "active_record/railtie"
        require "action_controller/railtie"
        require "action_view/railtie"
        require "rails/test_unit/railtie"
        require "solid_queue"
        require "solid_queue_monitor"
        
        module Dummy
          class Application < Rails::Application
            config.load_defaults Rails::VERSION::STRING.to_f
            
            # Settings in config/environments/* take precedence over those specified here.
            # Application configuration can go into files in config/initializers
            # -- all .rb files in that directory are automatically loaded after loading
            # the framework and any gems in your application.
            
            # Only loads a smaller set of middleware suitable for API only apps.
            # Middleware like session, flash, cookies can be added back manually.
            config.api_only = true
            
            # Don't generate system test files.
            config.generators.system_tests = nil
          end
        end
      RUBY
    end
    
    unless File.exist?(File.join(dummy_app_path, "config/environment.rb"))
      File.write(File.join(dummy_app_path, "config/environment.rb"), <<~RUBY)
        # Load the Rails application.
        require_relative 'application'
        
        # Initialize the Rails application.
        Rails.application.initialize!
      RUBY
    end
    
    unless File.exist?(File.join(dummy_app_path, "config/environments/test.rb"))
      File.write(File.join(dummy_app_path, "config/environments/test.rb"), <<~RUBY)
        Rails.application.configure do
          # Settings specified here will take precedence over those in config/application.rb.
        
          # The test environment is used exclusively to run your application's
          # test suite. You never need to work with it otherwise. Remember that
          # your test database is "scratch space" for the test suite and is wiped
          # and recreated between test runs. Don't rely on the data there!
          config.cache_classes = true
        
          # Do not eager load code on boot. This avoids loading your whole application
          # just for the purpose of running a single test. If you are using a tool that
          # preloads Rails for running tests, you may have to set it to true.
          config.eager_load = false
        
          # Configure public file server for tests with Cache-Control for performance.
          config.public_file_server.enabled = true
          config.public_file_server.headers = {
            'Cache-Control' => "public, max-age=\#{1.hour.to_i}"
          }
        
          # Show full error reports and disable caching.
          config.consider_all_requests_local       = true
          config.action_controller.perform_caching = false
        
          # Raise exceptions instead of rendering exception templates.
          config.action_dispatch.show_exceptions = false
        
          # Disable request forgery protection in test environment.
          config.action_controller.allow_forgery_protection = false
        
          # Print deprecation notices to the stderr.
          config.active_support.deprecation = :stderr
        
          # Raises error for missing translations.
          # config.action_view.raise_on_missing_translations = true
        end
      RUBY
    end
    
    unless File.exist?(File.join(dummy_app_path, "config/database.yml"))
      File.write(File.join(dummy_app_path, "config/database.yml"), <<~YAML)
        test:
          adapter: sqlite3
          database: ":memory:"
          pool: 5
          timeout: 5000
      YAML
    end
    
    unless File.exist?(File.join(dummy_app_path, "config/routes.rb"))
      File.write(File.join(dummy_app_path, "config/routes.rb"), <<~RUBY)
        Rails.application.routes.draw do
          mount SolidQueueMonitor::Engine => "/solid_queue"
        end
      RUBY
    end
    
    puts "Dummy app setup complete!"
  end
end