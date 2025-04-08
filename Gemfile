# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in solid_queue_monitor.gemspec
gemspec

# Rails version for development
gem 'rails', '~> 7.1.0' if ENV['RAILS_VERSION'].nil? || ENV['RAILS_VERSION'] == '7.1'
gem 'rails', '~> 7.0.0' if ENV['RAILS_VERSION'] == '7.0'
gem 'rails', '~> 7.2.0.alpha' if ENV['RAILS_VERSION'] == '7.2'

group :development, :test do
  gem 'database_cleaner-active_record', '~> 2.1.0'
  gem 'factory_bot_rails', '~> 6.4.0'
  gem 'ostruct'
  gem 'pg', '~> 1.5.0'
  gem 'rails-controller-testing', '~> 1.0.5'
  gem 'rspec-rails', '~> 6.1.0'
  gem 'rubocop', '~> 1.57.0'
  gem 'rubocop-rails', '~> 2.24.0'
  gem 'shoulda-matchers', '~> 6.0.0'

  # System test dependencies
  gem 'capybara', '~> 3.39.0'
  gem 'puma', '~> 6.0'
  gem 'rack', '~> 2.2'
  gem 'selenium-webdriver', '< 4.11.0'
  gem 'webdrivers', '~> 5.3.0'

  # Development dependencies
  gem 'debug', platforms: %i[mri mingw x64_mingw]
  gem 'solid_queue'
  gem 'sqlite3'
end
