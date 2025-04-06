# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'

require 'rails'
require 'solid_queue'
require 'solid_queue_monitor'

# Load the Rails application
ENV['RAILS_ENV'] = 'test'
require File.expand_path('dummy/config/environment', __dir__)

# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?

require 'rspec/rails'

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!

  # Configure RSpec to find spec files in the correct location
  config.pattern = 'spec/**/*_spec.rb'
end
