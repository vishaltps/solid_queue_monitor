# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolidQueueMonitor::BaseController, type: :controller, rails_required: true do
  controller do
    def index
      @jobs = paginate(SolidQueue::Job.all)
      @filtered_jobs = filter_jobs(SolidQueue::Job.all)
      render plain: 'Test'
    end
  end

  before do
    routes.draw { get 'index' => 'solid_queue_monitor/base#index' }
    allow(SolidQueueMonitor::AuthenticationService).to receive(:authentication_required?).and_return(false)
  end

  describe '#paginate' do
    let(:jobs) { create_list(:job, 5) }
    let(:paginated_result) { { records: jobs, current_page: 1, total_pages: 1 } }

    before do
      allow_any_instance_of(SolidQueueMonitor::PaginationService).to receive(:paginate).and_return(paginated_result)
    end

    it 'paginates the relation using PaginationService' do
      expect(SolidQueueMonitor::PaginationService).to receive(:new).with(any_args).and_call_original
      get :index
      expect(assigns(:jobs)).to eq(paginated_result)
    end

    it 'uses the current page from params' do
      expect(SolidQueueMonitor::PaginationService).to receive(:new).with(anything, 2, anything).and_call_original
      get :index, params: { page: 2 }
    end
  end

  describe '#filter_jobs' do
    let!(:default_job) { create(:job, queue_name: 'default', class_name: 'DefaultJob') }
    let!(:mailer_job) { create(:job, queue_name: 'mailers', class_name: 'MailerJob') }

    it 'filters by class_name' do
      get :index, params: { class_name: 'Default' }
      expect(controller.send(:filter_params)[:class_name]).to eq('Default')
    end

    it 'filters by queue_name' do
      get :index, params: { queue_name: 'mailers' }
      expect(controller.send(:filter_params)[:queue_name]).to eq('mailers')
    end

    it 'filters by status' do
      get :index, params: { status: 'failed' }
      expect(controller.send(:filter_params)[:status]).to eq('failed')
    end
  end

  describe '#render_page' do
    it 'renders the generated HTML' do
      controller.render_page('Test Title', 'Test Content')
      expect(response.body).to include('Test Title')
      expect(response.body).to include('Test Content')
    end

    it 'includes flash messages if present' do
      session[:flash_message] = 'Test Flash'
      session[:flash_type] = 'success'

      allow_any_instance_of(SolidQueueMonitor::HtmlGenerator).to receive(:generate).and_return('<div>HTML with flash</div>')

      controller.render_page('Test', 'Content')

      # Flash should be cleared after rendering
      expect(session[:flash_message]).to be_nil
      expect(session[:flash_type]).to be_nil
    end
  end

  describe '#current_page' do
    it 'returns page from params' do
      get :index, params: { page: '3' }
      expect(controller.send(:current_page)).to eq(3)
    end

    it 'defaults to 1 if page is not specified' do
      get :index
      expect(controller.send(:current_page)).to eq(1)
    end
  end

  describe '#per_page' do
    it 'returns jobs_per_page from SolidQueueMonitor configuration' do
      allow(SolidQueueMonitor).to receive(:jobs_per_page).and_return(50)
      expect(controller.send(:per_page)).to eq(50)
    end
  end
end
