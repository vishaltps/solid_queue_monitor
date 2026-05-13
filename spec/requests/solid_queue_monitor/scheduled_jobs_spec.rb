# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Scheduled Jobs' do
  describe 'GET /scheduled_jobs' do
    let!(:scheduled_job1) { create(:solid_queue_scheduled_execution, scheduled_at: 1.hour.from_now) }
    let!(:scheduled_job2) { create(:solid_queue_scheduled_execution, scheduled_at: 2.hours.from_now) }

    it 'returns a successful response' do
      get '/scheduled_jobs'

      expect(response).to have_http_status(:ok)
    end

    it 'displays the page title' do
      get '/scheduled_jobs'

      expect(response.body).to include('Scheduled Jobs')
    end

    it 'displays the scheduled jobs' do
      get '/scheduled_jobs'

      expect(response.body).to include(scheduled_job1.job.class_name)
    end

    context 'with no scheduled jobs' do
      before do
        SolidQueue::ScheduledExecution.delete_all
      end

      it 'still returns a successful response' do
        get '/scheduled_jobs'

        expect(response).to have_http_status(:ok)
      end
    end

    context 'with class_name filter' do
      let(:special_job) { create(:solid_queue_job, class_name: 'SpecialScheduledJob') }
      let!(:special_scheduled) { create(:solid_queue_scheduled_execution, job: special_job) }

      it 'filters by class name' do
        get '/scheduled_jobs', params: { class_name: 'Special' }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('SpecialScheduledJob')
      end
    end
  end
end
