# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Jobs' do
  describe 'GET /jobs/:id' do
    let(:job) { create(:solid_queue_job, class_name: 'MyTestJob', queue_name: 'default', priority: 5) }

    it 'returns a successful response' do
      get "/jobs/#{job.id}"

      expect(response).to have_http_status(:ok)
    end

    it 'displays the job details page' do
      get "/jobs/#{job.id}"

      expect(response.body).to include('MyTestJob')
      expect(response.body).to include('Job Details')
    end

    it 'displays the job queue and priority' do
      get "/jobs/#{job.id}"

      expect(response.body).to include('default')
      expect(response.body).to include('Priority')
    end

    context 'when job is not found' do
      it 'redirects to root with error message' do
        get '/jobs/999999'

        expect(response).to redirect_to('/')
      end
    end

    context 'with a failed job' do
      let(:failed_job) { create(:solid_queue_job, class_name: 'FailedTestJob') }
      let!(:failed_execution) do
        create(:solid_queue_failed_execution, job: failed_job, error: { 'message' => 'Test error', 'backtrace' => ['line 1', 'line 2'] })
      end

      it 'displays error information' do
        get "/jobs/#{failed_job.id}"

        expect(response.body).to include('Error')
        expect(response.body).to include('FailedTestJob')
      end

      it 'displays retry and discard buttons' do
        get "/jobs/#{failed_job.id}"

        expect(response.body).to include('Retry')
        expect(response.body).to include('Discard')
      end
    end

    context 'with an in-progress job' do
      let(:in_progress_job) { create(:solid_queue_job, class_name: 'InProgressJob') }
      let(:process) { create(:solid_queue_process, kind: 'Worker', hostname: 'worker-1') }
      let!(:claimed_execution) { create(:solid_queue_claimed_execution, job: in_progress_job, process_id: process.id) }

      it 'displays worker information' do
        get "/jobs/#{in_progress_job.id}"

        expect(response.body).to include('Worker')
        expect(response.body).to include('In Progress')
      end
    end

    context 'with a scheduled job' do
      let(:scheduled_job) { create(:solid_queue_job, :scheduled, class_name: 'ScheduledJob') }
      let!(:scheduled_execution) { create(:solid_queue_scheduled_execution, job: scheduled_job) }

      it 'displays scheduled status' do
        get "/jobs/#{scheduled_job.id}"

        expect(response.body).to include('ScheduledJob')
        expect(response.body).to include('Scheduled')
      end
    end

    context 'with a completed job' do
      let(:completed_job) { create(:solid_queue_job, :completed, class_name: 'CompletedJob') }

      it 'displays completed status' do
        get "/jobs/#{completed_job.id}"

        expect(response.body).to include('CompletedJob')
        expect(response.body).to include('Completed')
      end
    end
  end

  context 'with authentication enabled' do
    before do
      allow(SolidQueueMonitor).to receive_messages(authentication_enabled: true, username: 'admin', password: 'password123')
    end

    let(:job) { create(:solid_queue_job) }
    let(:valid_credentials) do
      ActionController::HttpAuthentication::Basic.encode_credentials('admin', 'password123')
    end

    it 'requires authentication for show' do
      get "/jobs/#{job.id}"

      expect(response).to have_http_status(:unauthorized)
    end

    it 'allows access with valid credentials' do
      get "/jobs/#{job.id}", headers: { 'HTTP_AUTHORIZATION' => valid_credentials }

      expect(response).to have_http_status(:ok)
    end
  end
end
