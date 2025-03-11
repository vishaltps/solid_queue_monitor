require 'spec_helper'

module SolidQueueMonitor
  RSpec.describe MonitorController, type: :controller do
    routes { SolidQueueMonitor::Engine.routes }

    let(:valid_credentials) { ActionController::HttpAuthentication::Basic.encode_credentials('admin', 'password123') }
    let(:invalid_credentials) { ActionController::HttpAuthentication::Basic.encode_credentials('wrong', 'wrong') }

    describe 'GET #index' do
      context 'with valid credentials' do
        before { request.env['HTTP_AUTHORIZATION'] = valid_credentials }

        it 'returns successful response' do
          get :index
          expect(response).to be_successful
        end

        it 'includes all required sections' do
          get :index
          expect(response.body).to include('Recent Jobs')
          expect(response.body).to include('Scheduled Jobs')
          expect(response.body).to include('Failed Jobs')
          expect(response.body).to include('Recurring Jobs')
        end
      end

      context 'with invalid credentials' do
        before { request.env['HTTP_AUTHORIZATION'] = invalid_credentials }

        it 'returns unauthorized' do
          get :index
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end

    describe 'POST #execute_job' do
      before { request.env['HTTP_AUTHORIZATION'] = valid_credentials }

      let(:scheduled_job) { create_scheduled_job }

      it 'moves job to ready queue' do
        expect {
          post :execute_job, params: { id: scheduled_job.id }
        }.to change(SolidQueue::ReadyExecution, :count).by(1)
          .and change(SolidQueue::ScheduledExecution, :count).by(-1)
      end

      it 'redirects with success message' do
        post :execute_job, params: { id: scheduled_job.id }
        expect(response).to redirect_to(root_path + '?message=Job moved to ready queue&message_type=success')
      end

      private

      def create_scheduled_job
        job = SolidQueue::Job.create!(
          class_name: 'TestJob',
          queue_name: 'default'
        )
        SolidQueue::ScheduledExecution.create!(
          job: job,
          queue_name: 'default',
          scheduled_at: 1.hour.from_now
        )
      end
    end
  end
end