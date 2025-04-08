# frozen_string_literal: true

require 'spec_helper'
require 'solid_queue_monitor'

RSpec.describe SolidQueueMonitor do
  describe '.setup' do
    it 'yields self to the block' do
      expect { |b| described_class.setup(&b) }.to yield_with_args(described_class)
    end

    it 'allows configuration to be set' do
      described_class.setup do |config|
        config.username = 'test_user'
        config.password = 'test_password'
        config.jobs_per_page = 50
        config.authentication_enabled = true
      end

      expect(described_class.username).to eq('test_user')
      expect(described_class.password).to eq('test_password')
      expect(described_class.jobs_per_page).to eq(50)
      expect(described_class.authentication_enabled).to eq(true)
    end
  end

  describe 'default configuration' do
    before do
      # Reset to default values before each test
      described_class.username = 'admin'
      described_class.password = 'password'
      described_class.jobs_per_page = 25
      described_class.authentication_enabled = false
    end

    it 'has default values' do
      expect(described_class.username).to eq('admin')
      expect(described_class.password).to eq('password')
      expect(described_class.jobs_per_page).to eq(25)
      expect(described_class.authentication_enabled).to eq(false)
    end
  end
end
