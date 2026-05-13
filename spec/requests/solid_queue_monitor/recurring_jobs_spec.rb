# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Recurring Jobs' do
  describe 'GET /recurring_jobs' do
    let!(:recurring_task1) do
      create(:solid_queue_recurring_task, key: 'daily_cleanup', class_name: 'DailyCleanupJob')
    end
    let!(:recurring_task2) do
      create(:solid_queue_recurring_task, key: 'hourly_metrics', class_name: 'HourlyMetricsJob')
    end

    it 'returns a successful response' do
      get '/recurring_jobs'

      expect(response).to have_http_status(:ok)
    end

    it 'displays the page title' do
      get '/recurring_jobs'

      expect(response.body).to include('Recurring Jobs')
    end

    it 'displays the recurring tasks' do
      get '/recurring_jobs'

      expect(response.body).to include('daily_cleanup')
      expect(response.body).to include('DailyCleanupJob')
    end

    context 'with no recurring tasks' do
      before do
        SolidQueue::RecurringTask.delete_all
      end

      it 'still returns a successful response' do
        get '/recurring_jobs'

        expect(response).to have_http_status(:ok)
      end
    end

    context 'with class_name filter' do
      it 'filters by class name' do
        get '/recurring_jobs', params: { class_name: 'DailyCleanup' }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('DailyCleanupJob')
      end
    end
  end
end
