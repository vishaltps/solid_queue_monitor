# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Overview', type: :request do
  # Note: Tests hit the engine directly at '/' instead of the mounted path '/solid_queue'
  describe 'GET /' do
    before do
      create_list(:solid_queue_job, 3)
      create(:solid_queue_job, :completed)
      create(:solid_queue_failed_execution)
      create(:solid_queue_scheduled_execution)
      create(:solid_queue_ready_execution)
    end

    it 'returns a successful response' do
      get '/'

      expect(response).to have_http_status(:ok)
    end

    it 'displays the dashboard title' do
      get '/'

      expect(response.body).to include('Solid Queue Monitor')
    end

    it 'displays job statistics' do
      get '/'

      expect(response.body).to include('Queue Statistics')
      expect(response.body).to include('Total Jobs')
    end

    it 'displays navigation links' do
      get '/'

      expect(response.body).to include('Overview')
      expect(response.body).to include('Queues')
      expect(response.body).to include('Failed')
    end
  end

  context 'with authentication enabled' do
    before do
      allow(SolidQueueMonitor).to receive(:authentication_enabled).and_return(true)
      allow(SolidQueueMonitor).to receive(:username).and_return('admin')
      allow(SolidQueueMonitor).to receive(:password).and_return('password123')
    end

    it 'requires authentication' do
      get '/'

      expect(response).to have_http_status(:unauthorized)
    end

    it 'allows access with valid credentials' do
      get '/', headers: {
        'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials('admin', 'password123')
      }

      expect(response).to have_http_status(:ok)
    end

    it 'rejects invalid credentials' do
      get '/', headers: {
        'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials('wrong', 'wrong')
      }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
