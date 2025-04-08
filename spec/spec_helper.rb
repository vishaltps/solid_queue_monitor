# frozen_string_literal: true

# This file is used for specs that don't need Rails
RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  # Use expect syntax
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Make tests run in random order to surface order dependencies
  config.order = :random
  Kernel.srand config.seed

  # Skip tests that need Rails unless specifically requested
  config.filter_run_excluding rails_required: true unless ENV['INCLUDE_RAILS_TESTS'] == 'true'

  # Handle RDoc warnings
  config.before(:suite) do
    # Suppress RDoc warnings by setting constants only once
    ENV['RDOC_WARNINGS_SUPPRESSED'] = '1' unless ENV['RDOC_WARNINGS_SUPPRESSED']
  end
end

# Set up basic environment and mocks
require 'ostruct'

# Core mocks that should be loaded first
require_relative 'support/mock_module' if File.exist?(File.expand_path('support/mock_module.rb', __dir__))

# Apply compatibility patches for Ruby 3.4 and Rails 8.0+
require_relative 'support/compatibility_patches' if File.exist?(File.expand_path('support/compatibility_patches.rb', __dir__))

# Load our test mocks
require_relative 'support/mock_rails_routes' if File.exist?(File.expand_path('support/mock_rails_routes.rb', __dir__))
require_relative 'support/mock_stylesheet_generator' if File.exist?(File.expand_path('support/mock_stylesheet_generator.rb', __dir__))
require_relative 'support/mock_controllers' if File.exist?(File.expand_path('support/mock_controllers.rb', __dir__))
require_relative 'support/mock_system' if File.exist?(File.expand_path('support/mock_system.rb', __dir__))
