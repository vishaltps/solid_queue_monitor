# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in solid_queue_monitor.gemspec
gemspec

group :development, :test do
  gem 'factory_bot_rails'
  gem 'rails-controller-testing'
  gem 'rspec-rails'
  gem 'rubocop'
  gem 'rubocop-rails'
  gem 'rubocop-rspec'
  gem 'sqlite3'
end

# Database adapters for running the suite beyond SQLite (see spec_helper.rb).
# Optional so a plain `bundle install` needs no MySQL or PostgreSQL client libs.
group :mysql, optional: true do
  gem 'mysql2'
end

group :postgresql, optional: true do
  gem 'pg'
end
