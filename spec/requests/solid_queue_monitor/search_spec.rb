# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Search' do
  describe 'GET /search' do
    it 'returns a successful response' do
      get '/search'

      expect(response).to have_http_status(:ok)
    end

    it 'displays the search page' do
      get '/search'

      expect(response.body).to include('Search')
      expect(response.body).to include('name="q"')
    end

    context 'without query parameter' do
      it 'shows enter search term message' do
        get '/search'

        expect(response.body).to include('Enter a search term')
      end
    end

    context 'with empty query parameter' do
      it 'shows enter search term message' do
        get '/search', params: { q: '' }

        expect(response.body).to include('Enter a search term')
      end
    end

    context 'with valid search query' do
      let!(:job) { create(:solid_queue_job, class_name: 'UserMailerJob', queue_name: 'mailers') }
      let!(:ready_execution) { create(:solid_queue_ready_execution, job: job) }

      it 'displays search results' do
        get '/search', params: { q: 'UserMailer' }

        expect(response.body).to include('UserMailerJob')
      end

      it 'shows the search query in results' do
        get '/search', params: { q: 'UserMailer' }

        expect(response.body).to include('UserMailer')
      end
    end

    context 'with no matching results' do
      it 'shows no results message' do
        get '/search', params: { q: 'NonExistentJob' }

        expect(response.body).to include('No results found')
      end
    end

    context 'when searching across different job types' do
      let!(:ready_job) { create(:solid_queue_job, class_name: 'TestSearchJob') }
      let!(:scheduled_job) { create(:solid_queue_job, class_name: 'TestSearchScheduled') }
      let!(:failed_job) { create(:solid_queue_job, class_name: 'TestSearchFailed') }
      let!(:ready_execution) { create(:solid_queue_ready_execution, job: ready_job) }
      let!(:scheduled_execution) { create(:solid_queue_scheduled_execution, job: scheduled_job) }
      let!(:failed_execution) { create(:solid_queue_failed_execution, job: failed_job, error: 'Test error') }

      it 'finds ready jobs' do
        get '/search', params: { q: 'TestSearchJob' }

        expect(response.body).to include('TestSearchJob')
        expect(response.body).to include('Ready Jobs')
      end

      it 'finds scheduled jobs' do
        get '/search', params: { q: 'TestSearchScheduled' }

        expect(response.body).to include('TestSearchScheduled')
        expect(response.body).to include('Scheduled Jobs')
      end

      it 'finds failed jobs' do
        get '/search', params: { q: 'TestSearchFailed' }

        expect(response.body).to include('TestSearchFailed')
        expect(response.body).to include('Failed Jobs')
      end
    end

    context 'when searching by error message' do
      let!(:job) { create(:solid_queue_job, class_name: 'SomeJob') }
      let!(:failed_execution) { create(:solid_queue_failed_execution, job: job, error: 'Connection refused to host') }

      it 'finds failed jobs by error message' do
        get '/search', params: { q: 'Connection refused' }

        expect(response.body).to include('SomeJob')
        expect(response.body).to include('Connection refused')
      end
    end

    context 'when searching recurring tasks' do
      let!(:recurring_task) { create(:solid_queue_recurring_task, key: 'daily_report_task', class_name: 'DailyReportJob') }

      it 'finds recurring tasks by key' do
        get '/search', params: { q: 'daily_report' }

        expect(response.body).to include('daily_report_task')
        expect(response.body).to include('Recurring Tasks')
      end
    end
  end

  context 'with authentication enabled' do
    before do
      allow(SolidQueueMonitor).to receive_messages(authentication_enabled: true, username: 'admin', password: 'password123')
    end

    let(:valid_credentials) do
      ActionController::HttpAuthentication::Basic.encode_credentials('admin', 'password123')
    end

    it 'requires authentication' do
      get '/search'

      expect(response).to have_http_status(:unauthorized)
    end

    it 'allows access with valid credentials' do
      get '/search', headers: { 'HTTP_AUTHORIZATION' => valid_credentials }

      expect(response).to have_http_status(:ok)
    end
  end
end
