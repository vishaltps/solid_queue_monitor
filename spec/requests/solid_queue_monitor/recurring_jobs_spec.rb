# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Recurring Jobs' do
  describe 'GET /recurring_jobs' do
    let(:recurring_task1) do
      create(:solid_queue_recurring_task, key: 'daily_cleanup', class_name: 'DailyCleanupJob')
    end
    let(:recurring_task2) do
      create(:solid_queue_recurring_task, key: 'hourly_metrics', class_name: 'HourlyMetricsJob')
    end

    before do
      recurring_task1
      recurring_task2
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
      expect(response.body).to include('Run now')
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

  describe 'POST /recurring_jobs/:id/enqueue' do
    include ActiveSupport::Testing::TimeHelpers

    let(:recurring_task) do
      create(:solid_queue_recurring_task, key: 'daily_cleanup', class_name: 'SolidQueueMonitorEnqueueProbeJob')
    end

    context 'when the task exists' do
      before { recurring_task }

      it 'enqueues the task immediately and redirects' do
        expect do
          post enqueue_recurring_job_path(recurring_task)
        end.to change(SolidQueue::Job, :count).by(1)
           .and change(SolidQueue::ReadyExecution, :count).by(1)

        expect(response).to redirect_to('/recurring_jobs')

        job = SolidQueue::Job.last
        expect(job.class_name).to eq('SolidQueueMonitorEnqueueProbeJob')
        expect(job.queue_name).to eq(recurring_task.queue_name)
        expect(recurring_task.reload.schedule).to eq('0 * * * *')
      end

      it 'does not enqueue a second copy for the same timestamp' do
        travel_to Time.zone.local(2026, 10, 7, 12, 0, 0) do
          post enqueue_recurring_job_path(recurring_task)

          expect do
            post enqueue_recurring_job_path(recurring_task)
          end.not_to change(SolidQueue::Job, :count)
        end

        expect(response).to redirect_to('/recurring_jobs')
      end
    end

    it 'redirects with an error when the task does not exist' do
      post enqueue_recurring_job_path(0)

      expect(response).to redirect_to('/recurring_jobs')
    end
  end
end
