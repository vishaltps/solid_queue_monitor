ENV["RAILS_ENV"] ||= "test"

# Create dummy app directories if they don't exist
dummy_app_path = File.expand_path("../dummy", __FILE__)
unless File.directory?(dummy_app_path)
  require 'fileutils'
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
end

require 'database_cleaner/active_record'
require 'factory_bot_rails'
require 'rails'
require 'active_record'
require 'solid_queue'
require 'solid_queue_monitor'

# Load the Rails application
ENV['RAILS_ENV'] = 'test'
require File.expand_path('../dummy/config/environment', __FILE__)

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?

require 'rspec/rails'

# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

# Configure RSpec
RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  # Use the specified formatter
  config.formatter = :documentation

  # Use FactoryBot methods without prefixing them with FactoryBot
  config.include FactoryBot::Syntax::Methods

  # Configure DatabaseCleaner
  config.before(:suite) do
    begin
      DatabaseCleaner.strategy = :transaction
      DatabaseCleaner.clean_with(:truncation)
    rescue => e
      puts "Error setting up DatabaseCleaner: #{e.message}"
      puts "Continuing with tests..."
    end
  end

  config.around(:each) do |example|
    begin
      DatabaseCleaner.cleaning do
        example.run
      end
    rescue => e
      puts "Error with DatabaseCleaner during test: #{e.message}"
      example.run
    end
  end

  # Include Rails route helpers
  config.include Rails.application.routes.url_helpers

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end