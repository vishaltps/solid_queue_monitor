# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Sorting' do
  describe 'Ready Jobs sorting' do
    let!(:job_a) { create(:solid_queue_job, class_name: 'AJob', queue_name: 'default', created_at: 2.hours.ago) }
    let!(:job_b) { create(:solid_queue_job, class_name: 'BJob', queue_name: 'high', created_at: 1.hour.ago) }
    let!(:ready_a) { create(:solid_queue_ready_execution, job: job_a, queue_name: 'default', priority: 10) }
    let!(:ready_b) { create(:solid_queue_ready_execution, job: job_b, queue_name: 'high', priority: 5) }

    it 'sorts by class_name ascending' do
      get '/ready_jobs', params: { sort_by: 'class_name', sort_direction: 'asc' }

      expect(response).to have_http_status(:ok)
      expect(response.body.index('AJob')).to be < response.body.index('BJob')
    end

    it 'sorts by class_name descending' do
      get '/ready_jobs', params: { sort_by: 'class_name', sort_direction: 'desc' }

      expect(response).to have_http_status(:ok)
      expect(response.body.index('BJob')).to be < response.body.index('AJob')
    end

    it 'sorts by queue_name' do
      get '/ready_jobs', params: { sort_by: 'queue_name', sort_direction: 'asc' }

      expect(response).to have_http_status(:ok)
      expect(response.body.index('default')).to be < response.body.index('high')
    end

    it 'sorts by priority' do
      get '/ready_jobs', params: { sort_by: 'priority', sort_direction: 'asc' }

      expect(response).to have_http_status(:ok)
      # Priority 5 should come before priority 10
      expect(response.body.index('BJob')).to be < response.body.index('AJob')
    end

    it 'uses default sort when invalid column provided' do
      get '/ready_jobs', params: { sort_by: 'invalid_column', sort_direction: 'asc' }

      expect(response).to have_http_status(:ok)
    end

    it 'shows sort indicator arrow' do
      get '/ready_jobs', params: { sort_by: 'class_name', sort_direction: 'asc' }

      expect(response.body).to include('&uarr;')
    end

    it 'shows descending arrow when sorting descending' do
      get '/ready_jobs', params: { sort_by: 'class_name', sort_direction: 'desc' }

      expect(response.body).to include('&darr;')
    end

    it 'includes sortable header links' do
      get '/ready_jobs'

      expect(response.body).to include('sortable-header')
      expect(response.body).to include('sort_by=class_name')
    end

    it 'shows default sort indicator on unsorted columns' do
      get '/ready_jobs'

      expect(response.body).to include('&udarr;')
    end
  end

  describe 'Scheduled Jobs sorting' do
    let!(:job_a) { create(:solid_queue_job, class_name: 'AJob') }
    let!(:job_b) { create(:solid_queue_job, class_name: 'BJob') }
    let!(:scheduled_a) { create(:solid_queue_scheduled_execution, job: job_a, scheduled_at: 2.hours.from_now) }
    let!(:scheduled_b) { create(:solid_queue_scheduled_execution, job: job_b, scheduled_at: 1.hour.from_now) }

    it 'sorts by scheduled_at ascending by default' do
      get '/scheduled_jobs'

      expect(response).to have_http_status(:ok)
      # Earlier scheduled time should come first
      expect(response.body.index('BJob')).to be < response.body.index('AJob')
    end

    it 'sorts by scheduled_at descending' do
      get '/scheduled_jobs', params: { sort_by: 'scheduled_at', sort_direction: 'desc' }

      expect(response).to have_http_status(:ok)
      expect(response.body.index('AJob')).to be < response.body.index('BJob')
    end

    it 'sorts by class_name' do
      get '/scheduled_jobs', params: { sort_by: 'class_name', sort_direction: 'asc' }

      expect(response).to have_http_status(:ok)
      expect(response.body.index('AJob')).to be < response.body.index('BJob')
    end
  end

  describe 'Failed Jobs sorting' do
    let!(:job_a) { create(:solid_queue_job, class_name: 'AFailedJob', queue_name: 'default') }
    let!(:job_b) { create(:solid_queue_job, class_name: 'BFailedJob', queue_name: 'high') }
    let!(:failed_a) { create(:solid_queue_failed_execution, job: job_a, created_at: 2.hours.ago) }
    let!(:failed_b) { create(:solid_queue_failed_execution, job: job_b, created_at: 1.hour.ago) }

    it 'sorts by created_at descending by default' do
      get '/failed_jobs'

      expect(response).to have_http_status(:ok)
      # More recent should come first
      expect(response.body.index('BFailedJob')).to be < response.body.index('AFailedJob')
    end

    it 'sorts by class_name ascending' do
      get '/failed_jobs', params: { sort_by: 'class_name', sort_direction: 'asc' }

      expect(response).to have_http_status(:ok)
      expect(response.body.index('AFailedJob')).to be < response.body.index('BFailedJob')
    end

    it 'sorts by queue_name' do
      get '/failed_jobs', params: { sort_by: 'queue_name', sort_direction: 'asc' }

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'Recurring Jobs sorting' do
    before do
      # Create recurring tasks directly
      SolidQueue::RecurringTask.create!(key: 'a_task', class_name: 'ARecurringJob', queue_name: 'default', schedule: '0 * * * *')
      SolidQueue::RecurringTask.create!(key: 'b_task', class_name: 'BRecurringJob', queue_name: 'high', schedule: '0 * * * *')
    end

    it 'sorts by key ascending by default' do
      get '/recurring_jobs'

      expect(response).to have_http_status(:ok)
      expect(response.body.index('a_task')).to be < response.body.index('b_task')
    end

    it 'sorts by key descending' do
      get '/recurring_jobs', params: { sort_by: 'key', sort_direction: 'desc' }

      expect(response).to have_http_status(:ok)
      expect(response.body.index('b_task')).to be < response.body.index('a_task')
    end

    it 'sorts by class_name' do
      get '/recurring_jobs', params: { sort_by: 'class_name', sort_direction: 'asc' }

      expect(response).to have_http_status(:ok)
      expect(response.body.index('ARecurringJob')).to be < response.body.index('BRecurringJob')
    end
  end

  describe 'Workers sorting' do
    let!(:worker_a) { create(:solid_queue_process, hostname: 'alpha-host', last_heartbeat_at: 1.minute.ago) }
    let!(:worker_b) { create(:solid_queue_process, hostname: 'beta-host', last_heartbeat_at: 2.minutes.ago) }

    it 'sorts by last_heartbeat_at descending by default' do
      get '/workers'

      expect(response).to have_http_status(:ok)
      # More recent heartbeat should come first
      expect(response.body.index('alpha-host')).to be < response.body.index('beta-host')
    end

    it 'sorts by hostname ascending' do
      get '/workers', params: { sort_by: 'hostname', sort_direction: 'asc' }

      expect(response).to have_http_status(:ok)
      expect(response.body.index('alpha-host')).to be < response.body.index('beta-host')
    end

    it 'sorts by hostname descending' do
      get '/workers', params: { sort_by: 'hostname', sort_direction: 'desc' }

      expect(response).to have_http_status(:ok)
      expect(response.body.index('beta-host')).to be < response.body.index('alpha-host')
    end
  end

  describe 'Overview page sorting' do
    let!(:job_a) { create(:solid_queue_job, class_name: 'AOverviewJob', created_at: 2.hours.ago) }
    let!(:job_b) { create(:solid_queue_job, class_name: 'BOverviewJob', created_at: 1.hour.ago) }

    it 'sorts by created_at descending by default' do
      get '/'

      expect(response).to have_http_status(:ok)
      # More recent should come first
      expect(response.body.index('BOverviewJob')).to be < response.body.index('AOverviewJob')
    end

    it 'sorts by class_name ascending' do
      get '/', params: { sort_by: 'class_name', sort_direction: 'asc' }

      expect(response).to have_http_status(:ok)
      expect(response.body.index('AOverviewJob')).to be < response.body.index('BOverviewJob')
    end
  end

  describe 'Queue details sorting' do
    let!(:job_a) { create(:solid_queue_job, class_name: 'AQueueJob', queue_name: 'test_queue', created_at: 2.hours.ago) }
    let!(:job_b) { create(:solid_queue_job, class_name: 'BQueueJob', queue_name: 'test_queue', created_at: 1.hour.ago) }

    it 'sorts by created_at descending by default' do
      get '/queues/test_queue'

      expect(response).to have_http_status(:ok)
      expect(response.body.index('BQueueJob')).to be < response.body.index('AQueueJob')
    end

    it 'sorts by class_name ascending' do
      get '/queues/test_queue', params: { sort_by: 'class_name', sort_direction: 'asc' }

      expect(response).to have_http_status(:ok)
      expect(response.body.index('AQueueJob')).to be < response.body.index('BQueueJob')
    end
  end

  describe 'Sorting with filters preserved' do
    let!(:job) { create(:solid_queue_job, class_name: 'FilteredJob', queue_name: 'filtered_queue') }
    let!(:ready) { create(:solid_queue_ready_execution, job: job, queue_name: 'filtered_queue') }

    it 'preserves filters when sorting' do
      get '/ready_jobs', params: { sort_by: 'class_name', sort_direction: 'asc', class_name: 'Filtered' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('FilteredJob')
      expect(response.body).to include('class_name=Filtered')
    end
  end

  describe 'Sorting with pagination' do
    before do
      # Create more jobs than a single page
      12.times do |i|
        job = create(:solid_queue_job, class_name: "Job#{format('%02d', i)}")
        create(:solid_queue_ready_execution, job: job)
      end
    end

    it 'preserves sorting when navigating pages' do
      get '/ready_jobs', params: { sort_by: 'class_name', sort_direction: 'asc', page: 2 }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('sort_by=class_name')
      expect(response.body).to include('sort_direction=asc')
    end
  end
end
