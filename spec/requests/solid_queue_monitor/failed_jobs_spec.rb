# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Failed Jobs' do
  describe 'GET /failed_jobs' do
    let!(:failed_job1) { create(:solid_queue_failed_execution, created_at: 1.hour.ago) }
    let!(:failed_job2) { create(:solid_queue_failed_execution, created_at: 2.hours.ago) }

    it 'returns a successful response' do
      get '/failed_jobs'

      expect(response).to have_http_status(:ok)
    end

    it 'displays failed jobs' do
      get '/failed_jobs'

      expect(response.body).to include('Failed Jobs')
    end

    context 'with filters' do
      let(:special_job) { create(:solid_queue_job, class_name: 'SpecialJob', queue_name: 'high_priority') }
      let!(:special_failed) { create(:solid_queue_failed_execution, job: special_job) }

      it 'filters by class name' do
        get '/failed_jobs', params: { class_name: 'Special' }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('SpecialJob')
      end

      it 'filters by queue name' do
        get '/failed_jobs', params: { queue_name: 'high_priority' }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('high_priority')
      end
    end
  end

  describe 'POST /retry_failed_job/:id' do
    let!(:failed_job) { create(:solid_queue_failed_execution) }

    it 'retries the job and redirects' do
      post "/retry_failed_job/#{failed_job.id}"

      expect(response).to redirect_to('/failed_jobs')
    end

    it 'removes the failed execution after retry' do
      expect do
        post "/retry_failed_job/#{failed_job.id}"
      end.to change(SolidQueue::FailedExecution, :count).by(-1)
    end

    context 'with custom redirect path' do
      it 'redirects to the specified path' do
        post "/retry_failed_job/#{failed_job.id}", params: { redirect_to: '/' }

        expect(response).to redirect_to('/')
      end
    end
  end

  describe 'POST /discard_failed_job/:id' do
    let!(:failed_job) { create(:solid_queue_failed_execution) }

    it 'discards the job and redirects' do
      post "/discard_failed_job/#{failed_job.id}"

      expect(response).to redirect_to('/failed_jobs')
    end

    it 'removes the failed execution after discard' do
      expect do
        post "/discard_failed_job/#{failed_job.id}"
      end.to change(SolidQueue::FailedExecution, :count).by(-1)
    end
  end

  describe 'POST /retry_failed_jobs' do
    let!(:failed_job1) { create(:solid_queue_failed_execution) }
    let!(:failed_job2) { create(:solid_queue_failed_execution) }

    it 'retries multiple jobs and redirects' do
      post '/retry_failed_jobs', params: { job_ids: [failed_job1.id, failed_job2.id] }

      expect(response).to redirect_to('/failed_jobs')
    end

    it 'handles empty job_ids gracefully' do
      post '/retry_failed_jobs', params: { job_ids: [] }

      expect(response).to redirect_to('/failed_jobs')
    end
  end

  describe 'POST /discard_failed_jobs' do
    let!(:failed_job1) { create(:solid_queue_failed_execution) }
    let!(:failed_job2) { create(:solid_queue_failed_execution) }

    it 'discards multiple jobs and redirects' do
      post '/discard_failed_jobs', params: { job_ids: [failed_job1.id, failed_job2.id] }

      expect(response).to redirect_to('/failed_jobs')
    end

    it 'handles empty job_ids gracefully' do
      post '/discard_failed_jobs', params: { job_ids: [] }

      expect(response).to redirect_to('/failed_jobs')
    end
  end

  context 'with authentication enabled' do
    before do
      allow(SolidQueueMonitor).to receive_messages(authentication_enabled: true, username: 'admin', password: 'password123')
    end

    let(:valid_credentials) do
      ActionController::HttpAuthentication::Basic.encode_credentials('admin', 'password123')
    end

    it 'requires authentication for index' do
      get '/failed_jobs'

      expect(response).to have_http_status(:unauthorized)
    end

    it 'allows access with valid credentials' do
      get '/failed_jobs', headers: { 'HTTP_AUTHORIZATION' => valid_credentials }

      expect(response).to have_http_status(:ok)
    end

    it 'requires authentication for retry action' do
      failed_job = create(:solid_queue_failed_execution)
      post "/retry_failed_job/#{failed_job.id}"

      expect(response).to have_http_status(:unauthorized)
    end

    it 'requires authentication for discard action' do
      failed_job = create(:solid_queue_failed_execution)
      post "/discard_failed_job/#{failed_job.id}"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
