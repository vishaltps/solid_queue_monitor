# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolidQueueMonitor::OverviewController, type: :controller do
  routes { SolidQueueMonitor::Engine.routes }

  describe 'GET #index' do
    let(:stats) { { total_jobs: 10, ready_jobs: 5, scheduled_jobs: 2, failed_jobs: 1, in_progress_jobs: 2 } }
    let(:jobs) { create_list(:job, 3) }
    let(:paginated_jobs) { { records: jobs, current_page: 1, total_pages: 1 } }

    before do
      # Disable authentication for testing
      allow(SolidQueueMonitor::AuthenticationService).to receive(:authentication_required?).and_return(false)

      # Mock StatsCalculator
      allow(SolidQueueMonitor::StatsCalculator).to receive(:calculate).and_return(stats)

      # Mock filters and pagination
      allow_any_instance_of(described_class).to receive(:filter_jobs).and_return(SolidQueue::Job.all)
      allow_any_instance_of(described_class).to receive(:paginate).and_return(paginated_jobs)

      # Mock presenters
      allow_any_instance_of(SolidQueueMonitor::StatsPresenter).to receive(:render).and_return('<div class="stats">Stats</div>')
      allow_any_instance_of(SolidQueueMonitor::JobsPresenter).to receive(:render).and_return('<div class="jobs">Jobs</div>')
    end

    it 'assigns stats' do
      get :index
      expect(assigns(:stats)).to eq(stats)
    end

    it 'assigns recent jobs' do
      get :index
      expect(assigns(:recent_jobs)).to eq(paginated_jobs)
    end

    it 'renders the overview page' do
      get :index
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<div class="stats">Stats</div>')
      expect(response.body).to include('<div class="jobs">Jobs</div>')
    end

    context 'with filter parameters' do
      it 'applies filters to jobs' do
        expect_any_instance_of(described_class).to receive(:filter_jobs).with(kind_of(ActiveRecord::Relation)).and_return(SolidQueue::Job.all)
        get :index, params: { class_name: 'TestJob', queue_name: 'default' }
      end
    end
  end
end
