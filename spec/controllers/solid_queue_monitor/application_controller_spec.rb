# frozen_string_literal: true

require 'spec_helper'
require 'base64'

RSpec.describe 'SolidQueueMonitor::ApplicationController' do
  include MockRequest

  before do
    # Reset authentication settings before each test
    SolidQueueMonitor.authentication_enabled = false
    SolidQueueMonitor.username = 'admin'
    SolidQueueMonitor.password = 'password'
  end

  let(:controller) { SolidQueueMonitor::MockApplicationController.new }

  describe 'authentication' do
    context 'when authentication is disabled' do
      before do
        SolidQueueMonitor.authentication_enabled = false
      end

      it 'allows access without authentication' do
        response = get '/index'
        expect(response.status).to eq(200)
      end
    end

    context 'when authentication is enabled' do
      before do
        SolidQueueMonitor.authentication_enabled = true
      end

      it 'allows access with correct credentials' do
        auth_header = "Basic #{Base64.encode64('admin:password').strip}"
        response = get '/index', params: { 'Authorization' => auth_header }
        expect(response.status).to eq(200)
      end
    end
  end
end
