# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidQueueMonitor::AuthenticationService do
  before do
    # Reset authentication settings before each test
    SolidQueueMonitor.authentication_enabled = false
    SolidQueueMonitor.username = 'admin'
    SolidQueueMonitor.password = 'password'
  end

  describe '.authentication_required?' do
    it 'returns false when authentication is disabled' do
      SolidQueueMonitor.authentication_enabled = false
      expect(described_class.authentication_required?).to be false
    end

    it 'returns true when authentication is enabled' do
      SolidQueueMonitor.authentication_enabled = true
      expect(described_class.authentication_required?).to be true
    end
  end

  describe '.authenticate' do
    before do
      SolidQueueMonitor.authentication_enabled = true
    end

    it 'always returns true when authentication is disabled' do
      SolidQueueMonitor.authentication_enabled = false
      expect(described_class.authenticate('wrong', 'wrong')).to be true
    end

    it 'returns true for correct credentials' do
      expect(described_class.authenticate('admin', 'password')).to be true
    end

    it 'returns false for incorrect username' do
      expect(described_class.authenticate('wrong', 'password')).to be false
    end

    it 'returns false for incorrect password' do
      expect(described_class.authenticate('admin', 'wrong')).to be false
    end
  end
end
