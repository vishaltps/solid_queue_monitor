# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Queues', type: :request do
  describe 'GET /queues' do
    before do
      create(:solid_queue_job, queue_name: 'default')
      create(:solid_queue_job, queue_name: 'default')
      create(:solid_queue_job, queue_name: 'high_priority')
    end

    it 'returns a successful response' do
      get '/queues'

      expect(response).to have_http_status(:ok)
    end

    it 'displays queue information' do
      get '/queues'

      expect(response.body).to include('default')
      expect(response.body).to include('high_priority')
    end

    context 'with paused queues' do
      before do
        create(:solid_queue_pause, queue_name: 'default')
      end

      it 'shows paused status for paused queues' do
        get '/queues'

        expect(response.body).to include('Paused')
      end
    end
  end

  describe 'POST /pause_queue' do
    let(:queue_name) { 'default' }

    context 'when queue is not paused' do
      it 'pauses the queue successfully' do
        post '/pause_queue', params: { queue_name: queue_name }

        expect(response).to redirect_to('/queues')
        expect(SolidQueue::Pause.exists?(queue_name: queue_name)).to be true
      end

      it 'creates a pause record' do
        expect {
          post '/pause_queue', params: { queue_name: queue_name }
        }.to change { SolidQueue::Pause.count }.by(1)
      end
    end

    context 'when queue is already paused' do
      before do
        create(:solid_queue_pause, queue_name: queue_name)
      end

      it 'does not create another pause record' do
        expect {
          post '/pause_queue', params: { queue_name: queue_name }
        }.not_to change { SolidQueue::Pause.count }
      end

      it 'still redirects to queues' do
        post '/pause_queue', params: { queue_name: queue_name }

        expect(response).to redirect_to('/queues')
      end
    end
  end

  describe 'POST /resume_queue' do
    let(:queue_name) { 'default' }

    context 'when queue is paused' do
      before do
        create(:solid_queue_pause, queue_name: queue_name)
      end

      it 'resumes the queue successfully' do
        post '/resume_queue', params: { queue_name: queue_name }

        expect(response).to redirect_to('/queues')
        expect(SolidQueue::Pause.exists?(queue_name: queue_name)).to be false
      end

      it 'removes the pause record' do
        expect {
          post '/resume_queue', params: { queue_name: queue_name }
        }.to change { SolidQueue::Pause.count }.by(-1)
      end
    end

    context 'when queue is not paused' do
      it 'does not change pause count' do
        expect {
          post '/resume_queue', params: { queue_name: queue_name }
        }.not_to change { SolidQueue::Pause.count }
      end

      it 'still redirects to queues' do
        post '/resume_queue', params: { queue_name: queue_name }

        expect(response).to redirect_to('/queues')
      end
    end
  end

  context 'with authentication enabled' do
    before do
      allow(SolidQueueMonitor).to receive(:authentication_enabled).and_return(true)
      allow(SolidQueueMonitor).to receive(:username).and_return('admin')
      allow(SolidQueueMonitor).to receive(:password).and_return('password123')
    end

    it 'requires authentication for queues index' do
      get '/queues'

      expect(response).to have_http_status(:unauthorized)
    end

    it 'allows access with valid credentials' do
      get '/queues', headers: {
        'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials('admin', 'password123')
      }

      expect(response).to have_http_status(:ok)
    end

    it 'requires authentication for pause action' do
      post '/pause_queue', params: { queue_name: 'default' }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'requires authentication for resume action' do
      post '/resume_queue', params: { queue_name: 'default' }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
