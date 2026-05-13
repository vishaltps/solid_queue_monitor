# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Ready Jobs' do
  describe 'GET /ready_jobs' do
    let!(:ready_job1) { create(:solid_queue_ready_execution, created_at: 1.hour.ago) }
    let!(:ready_job2) { create(:solid_queue_ready_execution, created_at: 2.hours.ago) }

    it 'returns a successful response' do
      get '/ready_jobs'

      expect(response).to have_http_status(:ok)
    end

    it 'displays the page title' do
      get '/ready_jobs'

      expect(response.body).to include('Ready Jobs')
    end

    it 'displays the ready jobs' do
      get '/ready_jobs'

      expect(response.body).to include(ready_job1.job.class_name)
    end

    context 'with no ready jobs' do
      before do
        SolidQueue::ReadyExecution.delete_all
      end

      it 'still returns a successful response' do
        get '/ready_jobs'

        expect(response).to have_http_status(:ok)
      end
    end

    context 'with class_name filter' do
      let(:special_job) { create(:solid_queue_job, class_name: 'SpecialReadyJob') }
      let!(:special_ready) { create(:solid_queue_ready_execution, job: special_job) }

      it 'filters by class name' do
        get '/ready_jobs', params: { class_name: 'Special' }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('SpecialReadyJob')
      end
    end

    context 'with queue_name filter' do
      let(:queue_job) { create(:solid_queue_job, queue_name: 'priority_lane') }
      let!(:queue_ready) { create(:solid_queue_ready_execution, job: queue_job, queue_name: 'priority_lane') }

      it 'filters by queue name' do
        get '/ready_jobs', params: { queue_name: 'priority_lane' }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('priority_lane')
      end
    end
  end
end
