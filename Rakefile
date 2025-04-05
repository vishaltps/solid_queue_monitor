# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

namespace :db do
  task setup: :environment do
    require 'fileutils'
    FileUtils.mkdir_p 'spec/dummy/db'
    system('cd spec/dummy && bundle exec rails db:environment:set RAILS_ENV=test')
    system('cd spec/dummy && bundle exec rails db:schema:load RAILS_ENV=test')
  end
end

task prepare_test_env: :environment do
  Rake::Task['db:setup'].invoke
end

task spec: :prepare_test_env
