# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'In Progress Jobs' do
  describe 'GET /in_progress_jobs' do
    let!(:claimed_job1) { create(:solid_queue_claimed_execution, created_at: 1.hour.ago) }
    let!(:claimed_job2) { create(:solid_queue_claimed_execution, created_at: 2.hours.ago) }

    it 'returns a successful response' do
      get '/in_progress_jobs'

      expect(response).to have_http_status(:ok)
    end

    it 'displays the page title' do
      get '/in_progress_jobs'

      expect(response.body).to include('In Progress')
    end

    it 'displays the claimed jobs' do
      get '/in_progress_jobs'

      expect(response.body).to include(claimed_job1.job.class_name)
    end

    context 'with no claimed jobs' do
      before do
        SolidQueue::ClaimedExecution.delete_all
      end

      it 'still returns a successful response' do
        get '/in_progress_jobs'

        expect(response).to have_http_status(:ok)
      end
    end

    context 'with class_name filter' do
      let(:special_job) { create(:solid_queue_job, class_name: 'SpecialInProgressJob') }
      let!(:special_claimed) { create(:solid_queue_claimed_execution, job: special_job) }

      it 'filters by class name' do
        get '/in_progress_jobs', params: { class_name: 'Special' }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('SpecialInProgressJob')
      end
    end
  end
end
