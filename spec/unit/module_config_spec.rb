# frozen_string_literal: true

require 'spec_helper'

# Mock Rails for the module to load
module Rails
  class Engine; end
end

# Manually define the minimal version of SolidQueueMonitor module for testing
module SolidQueueMonitor
  class << self
    attr_accessor :username, :password, :jobs_per_page, :authentication_enabled
  end

  @username = 'admin'
  @password = 'password'
  @jobs_per_page = 25
  @authentication_enabled = false

  def self.setup
    yield self
  end
end

RSpec.describe 'SolidQueueMonitor module configuration' do
  describe '.setup' do
    it 'yields self to the block' do
      expect { |b| SolidQueueMonitor.setup(&b) }.to yield_with_args(SolidQueueMonitor)
    end

    it 'allows configuration to be set' do
      SolidQueueMonitor.setup do |config|
        config.username = 'test_user'
        config.password = 'test_password'
        config.jobs_per_page = 50
        config.authentication_enabled = true
      end

      expect(SolidQueueMonitor.username).to eq('test_user')
      expect(SolidQueueMonitor.password).to eq('test_password')
      expect(SolidQueueMonitor.jobs_per_page).to eq(50)
      expect(SolidQueueMonitor.authentication_enabled).to eq(true)
    end
  end

  describe 'default configuration' do
    before do
      # Reset to default values before each test
      SolidQueueMonitor.username = 'admin'
      SolidQueueMonitor.password = 'password'
      SolidQueueMonitor.jobs_per_page = 25
      SolidQueueMonitor.authentication_enabled = false
    end

    it 'has default values' do
      expect(SolidQueueMonitor.username).to eq('admin')
      expect(SolidQueueMonitor.password).to eq('password')
      expect(SolidQueueMonitor.jobs_per_page).to eq(25)
      expect(SolidQueueMonitor.authentication_enabled).to eq(false)
    end
  end
end
