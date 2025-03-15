require 'spec_helper'

module SolidQueueMonitor
  RSpec.describe MonitorController, type: :controller do
    routes { SolidQueueMonitor::Engine.routes }

    let(:valid_credentials) { ActionController::HttpAuthentication::Basic.encode_credentials('admin', 'password123') }
    let(:invalid_credentials) { ActionController::HttpAuthentication::Basic.encode_credentials('wrong', 'wrong') }

    before do
      # Skip authentication for tests
      allow(SolidQueueMonitor::AuthenticationService).to receive(:authentication_required?).and_return(false)
    end

    describe 'GET #index' do
      before do
        create_list(:solid_queue_job, 3)
        create(:solid_queue_job, :completed)
      end

      it 'returns a successful response' do
        get :index
        expect(response).to be_successful
      end

      it 'assigns stats and recent jobs' do
        get :index
        
        expect(assigns(:stats)).to be_present
        expect(assigns(:recent_jobs)).to be_present
        expect(assigns(:recent_jobs)[:records].size).to eq(4)
      end

      context 'with filters' do
        it 'filters jobs by class name' do
          create(:solid_queue_job, class_name: 'SpecialJob')
          
          get :index, params: { class_name: 'Special' }
          
          expect(assigns(:recent_jobs)[:records].size).to eq(1)
          expect(assigns(:recent_jobs)[:records].first.class_name).to eq('SpecialJob')
        end
        
        it 'filters jobs by queue name' do
          create(:solid_queue_job, queue_name: 'high_priority')
          
          get :index, params: { queue_name: 'high' }
          
          expect(assigns(:recent_jobs)[:records].size).to eq(1)
          expect(assigns(:recent_jobs)[:records].first.queue_name).to eq('high_priority')
        end
        
        it 'filters jobs by status' do
          get :index, params: { status: 'completed' }
          
          expect(assigns(:recent_jobs)[:records].size).to eq(1)
          expect(assigns(:recent_jobs)[:records].first.finished_at).to be_present
        end
      end
    end

    describe 'GET #ready_jobs' do
      before do
        create_list(:solid_queue_ready_execution, 2)
      end
      
      it 'returns a successful response' do
        get :ready_jobs
        expect(response).to be_successful
      end
      
      it 'assigns ready jobs' do
        get :ready_jobs
        
        expect(assigns(:ready_jobs)).to be_present
        expect(assigns(:ready_jobs)[:records].size).to eq(2)
      end
    end

    describe 'GET #scheduled_jobs' do
      before do
        create_list(:solid_queue_scheduled_execution, 2)
      end
      
      it 'returns a successful response' do
        get :scheduled_jobs
        expect(response).to be_successful
      end
      
      it 'assigns scheduled jobs' do
        get :scheduled_jobs
        
        expect(assigns(:scheduled_jobs)).to be_present
        expect(assigns(:scheduled_jobs)[:records].size).to eq(2)
      end
    end

    describe 'GET #failed_jobs' do
      before do
        create_list(:solid_queue_failed_execution, 2)
      end
      
      it 'returns a successful response' do
        get :failed_jobs
        expect(response).to be_successful
      end
      
      it 'assigns failed jobs' do
        get :failed_jobs
        
        expect(assigns(:failed_jobs)).to be_present
        expect(assigns(:failed_jobs)[:records].size).to eq(2)
      end
    end

    describe 'GET #queues' do
      before do
        create(:solid_queue_job, queue_name: 'default')
        create(:solid_queue_job, queue_name: 'default')
        create(:solid_queue_job, queue_name: 'high_priority')
      end
      
      it 'returns a successful response' do
        get :queues
        expect(response).to be_successful
      end
      
      it 'assigns queues with job counts' do
        get :queues
        
        expect(assigns(:queues)).to be_present
        expect(assigns(:queues).size).to eq(2)
      end
    end

    describe 'POST #execute_jobs' do
      let!(:scheduled_execution) { create(:solid_queue_scheduled_execution) }
      
      it 'redirects after execution' do
        post :execute_jobs, params: { job_ids: [scheduled_execution.id] }
        
        expect(response).to be_redirect
        expect(response).to redirect_to(scheduled_jobs_path(message: 'Selected jobs moved to ready queue', message_type: 'success'))
      end
      
      it 'creates a ready execution and deletes the scheduled execution' do
        expect {
          post :execute_jobs, params: { job_ids: [scheduled_execution.id] }
        }.to change(SolidQueue::ReadyExecution, :count).by(1)
         .and change(SolidQueue::ScheduledExecution, :count).by(-1)
      end
      
      it 'redirects with error when no jobs are selected' do
        post :execute_jobs
        
        expect(response).to be_redirect
        expect(response).to redirect_to(scheduled_jobs_path(message: 'No jobs selected', message_type: 'error'))
      end
    end

    describe 'GET #recurring_jobs' do
      before do
        # Create some recurring tasks for testing
        create(:solid_queue_recurring_task, key: 'daily_report', class_name: 'DailyReportJob', schedule: 'every 24h')
        create(:solid_queue_recurring_task, key: 'hourly_cleanup', class_name: 'CleanupJob', schedule: 'every 1h')
      end
      
      it 'returns a successful response' do
        get :recurring_jobs
        expect(response).to be_successful
      end
      
      it 'assigns recurring jobs' do
        get :recurring_jobs
        
        expect(assigns(:recurring_jobs)).to be_present
        expect(assigns(:recurring_jobs)[:records].size).to eq(2)
      end
      
      context 'with filters' do
        it 'filters jobs by class name' do
          get :recurring_jobs, params: { class_name: 'Cleanup' }
          
          expect(assigns(:recurring_jobs)[:records].size).to eq(1)
          expect(assigns(:recurring_jobs)[:records].first.class_name).to eq('CleanupJob')
        end
        
        it 'filters jobs by queue name' do
          create(:solid_queue_recurring_task, key: 'priority_task', class_name: 'PriorityJob', queue_name: 'high_priority')
          
          get :recurring_jobs, params: { queue_name: 'high' }
          
          expect(assigns(:recurring_jobs)[:records].size).to eq(1)
          expect(assigns(:recurring_jobs)[:records].first.queue_name).to eq('high_priority')
        end
      end
    end
  end
end