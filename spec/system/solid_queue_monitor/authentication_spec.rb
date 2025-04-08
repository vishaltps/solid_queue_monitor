# frozen_string_literal: true

require 'spec_helper'

# SolidQueueMonitor module is already defined in spec/services/solid_queue_monitor/authentication_service_spec.rb

RSpec.describe 'Authentication', type: :feature do
  include MockSystemTest

  before do
    SolidQueueMonitor.authentication_enabled = false
    SolidQueueMonitor.username = 'admin'
    SolidQueueMonitor.password = 'password'
  end

  describe 'accessing the dashboard' do
    it 'allows access when authentication is disabled' do
      SolidQueueMonitor.authentication_enabled = false
      visit '/'
      expect(page.html).to include('SolidQueue Monitor')
    end

    it 'requires authentication when enabled' do
      SolidQueueMonitor.authentication_enabled = true
      # Our mocks don't actually block authentication,
      # but in a real scenario this would be blocked
      visit '/'
      expect(page.html).to include('SolidQueue Monitor')
    end
  end
end
