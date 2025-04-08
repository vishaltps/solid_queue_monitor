# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'

# Set up the database configuration before loading the environment
ENV['DATABASE_URL'] ||= 'postgresql://postgres:postgres@localhost/solid_queue_monitor_test'

# Load the Rails application from our dummy app
require File.expand_path('dummy/config/environment', __dir__)

# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?

require 'rspec/rails'
require 'factory_bot_rails'
require 'capybara/rails'
require 'capybara/rspec'

# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.expand_path('support/**/*.rb', __dir__)].each { |f| require f }

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = ["#{File.dirname(__FILE__)}/fixtures"]

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!

  # Include FactoryBot methods
  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    # Skip database setup/cleaning since we don't have a proper database connection yet
    # We'll mock the database access for now
  end

  # Configure system tests
  config.before(:each, type: :system) do
    driven_by :rack_test
  end
end

# Configure Capybara for all tests
Capybara.configure do |config|
  config.default_driver = :rack_test
  config.javascript_driver = :rack_test
  config.server = :puma, { Silent: true }
  config.default_max_wait_time = 5
  # Disable screenshots for rack_test failures
  config.save_path = '/dev/null'
end

# Configure Shoulda Matchers
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

# Add global test helpers
module TestHelpers
  # Helper to stub authentication values
  def stub_authentication(enabled: false, username: 'admin', password: 'password')
    allow(SolidQueueMonitor).to receive(:authentication_enabled).and_return(enabled)
    allow(SolidQueueMonitor).to receive(:username).and_return(username)
    allow(SolidQueueMonitor).to receive(:password).and_return(password)
  end

  # Helper to stub database queries for system tests
  def stub_solid_queue_models
    # Stub SolidQueue::Job.count to return different values based on status
    allow_any_instance_of(ActiveRecord::Relation).to receive(:count).and_return(5)

    # Stub model creation and queries
    allow(SolidQueue::Job).to receive(:create!).and_return(double('Job', id: 1))
    allow(SolidQueue::Job).to receive(:find_by).and_return(double('Job', id: 1, queue_name: 'default'))

    # Add more stubs as needed for your tests
  end
end

RSpec.configure do |config|
  config.include TestHelpers
end
