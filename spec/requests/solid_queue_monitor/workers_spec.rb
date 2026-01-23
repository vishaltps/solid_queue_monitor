# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Workers' do
  describe 'GET /workers' do
    context 'with no processes' do
      it 'returns a successful response' do
        get '/workers'

        expect(response).to have_http_status(:ok)
      end

      it 'displays empty state message' do
        get '/workers'

        expect(response.body).to include('No worker processes found')
      end
    end

    context 'with processes' do
      before do
        create(:solid_queue_process, kind: 'Worker', hostname: 'worker-1', pid: 1001, last_heartbeat_at: Time.current)
        create(:solid_queue_process, kind: 'Dispatcher', hostname: 'dispatcher-1', pid: 1002, last_heartbeat_at: Time.current)
        create(:solid_queue_process, kind: 'Scheduler', hostname: 'scheduler-1', pid: 1003, last_heartbeat_at: 15.minutes.ago)
      end

      it 'returns a successful response' do
        get '/workers'

        expect(response).to have_http_status(:ok)
      end

      it 'displays process information' do
        get '/workers'

        expect(response.body).to include('worker-1')
        expect(response.body).to include('dispatcher-1')
        expect(response.body).to include('scheduler-1')
      end

      it 'displays kind badges' do
        get '/workers'

        expect(response.body).to include('Worker')
        expect(response.body).to include('Dispatcher')
        expect(response.body).to include('Scheduler')
      end

      it 'displays status badges' do
        get '/workers'

        expect(response.body).to include('Healthy')
        expect(response.body).to include('Dead')
      end

      it 'displays summary counts' do
        get '/workers'

        expect(response.body).to include('Total Processes')
      end

      it 'displays Actions column' do
        get '/workers'

        expect(response.body).to include('<th>Actions</th>')
      end

      it 'shows Remove button for dead processes' do
        get '/workers'

        expect(response.body).to include('Remove')
      end

      it 'shows Prune all link when dead processes exist' do
        get '/workers'

        expect(response.body).to include('Prune all')
      end
    end

    context 'with only healthy processes' do
      before do
        create(:solid_queue_process, kind: 'Worker', hostname: 'worker-1', last_heartbeat_at: Time.current)
      end

      it 'does not show Prune all link' do
        get '/workers'

        expect(response.body).not_to include('Prune all')
      end
    end

    context 'with filters' do
      before do
        create(:solid_queue_process, kind: 'Worker', hostname: 'worker-1', last_heartbeat_at: Time.current)
        create(:solid_queue_process, kind: 'Dispatcher', hostname: 'dispatcher-1', last_heartbeat_at: Time.current)
      end

      it 'filters by kind' do
        get '/workers', params: { kind: 'Worker' }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('worker-1')
        expect(response.body).not_to include('dispatcher-1')
      end

      it 'filters by hostname' do
        get '/workers', params: { hostname: 'dispatcher' }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('dispatcher-1')
        expect(response.body).not_to include('worker-1')
      end

      it 'filters by status' do
        create(:solid_queue_process, kind: 'Worker', hostname: 'dead-worker', last_heartbeat_at: 15.minutes.ago)

        get '/workers', params: { status: 'dead' }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('dead-worker')
      end
    end

    context 'with stale process' do
      before do
        create(:solid_queue_process, kind: 'Worker', hostname: 'stale-worker', last_heartbeat_at: 7.minutes.ago)
      end

      it 'shows stale status' do
        get '/workers'

        expect(response.body).to include('Stale')
      end
    end
  end

  describe 'POST /remove_worker/:id' do
    context 'with a dead process' do
      let!(:dead_process) do
        create(:solid_queue_process, kind: 'Worker', hostname: 'dead-worker', last_heartbeat_at: 15.minutes.ago)
      end

      it 'removes the process' do
        expect do
          post "/remove_worker/#{dead_process.id}"
        end.to change(SolidQueue::Process, :count).by(-1)
      end

      it 'redirects to workers page' do
        post "/remove_worker/#{dead_process.id}"

        expect(response).to redirect_to('/workers')
      end
    end

    context 'with non-existent process' do
      it 'handles gracefully' do
        post '/remove_worker/99999'

        expect(response).to redirect_to('/workers')
      end
    end
  end

  describe 'POST /prune_workers' do
    context 'with dead processes' do
      before do
        create(:solid_queue_process, kind: 'Worker', hostname: 'healthy-worker', last_heartbeat_at: Time.current)
        create(:solid_queue_process, kind: 'Worker', hostname: 'dead-worker-1', last_heartbeat_at: 15.minutes.ago)
        create(:solid_queue_process, kind: 'Worker', hostname: 'dead-worker-2', last_heartbeat_at: 20.minutes.ago)
      end

      it 'removes dead processes' do
        expect do
          post '/prune_workers'
        end.to change(SolidQueue::Process, :count).by(-2)
      end

      it 'keeps healthy processes' do
        post '/prune_workers'

        expect(SolidQueue::Process.where(hostname: 'healthy-worker')).to exist
      end

      it 'redirects to workers page' do
        post '/prune_workers'

        expect(response).to redirect_to('/workers')
      end
    end

    context 'with no dead processes' do
      before do
        create(:solid_queue_process, kind: 'Worker', hostname: 'healthy-worker', last_heartbeat_at: Time.current)
      end

      it 'does not remove any processes' do
        expect do
          post '/prune_workers'
        end.not_to(change(SolidQueue::Process, :count))
      end

      it 'redirects to workers page' do
        post '/prune_workers'

        expect(response).to redirect_to('/workers')
      end
    end
  end

  context 'with authentication enabled' do
    before do
      allow(SolidQueueMonitor).to receive_messages(authentication_enabled: true, username: 'admin', password: 'password123')
    end

    it 'requires authentication for workers index' do
      get '/workers'

      expect(response).to have_http_status(:unauthorized)
    end

    it 'allows access with valid credentials' do
      get '/workers', headers: {
        'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials('admin', 'password123')
      }

      expect(response).to have_http_status(:ok)
    end

    it 'requires authentication for remove action' do
      post '/remove_worker/1'

      expect(response).to have_http_status(:unauthorized)
    end

    it 'requires authentication for prune action' do
      post '/prune_workers'

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
