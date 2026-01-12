# frozen_string_literal: true

require 'spec_helper'

module SolidQueueMonitor
  RSpec.describe FailedJobsController, type: :controller do

    let(:valid_credentials) { ActionController::HttpAuthentication::Basic.encode_credentials('admin', 'password123') }

    before do
      # Skip authentication for tests by default
      allow(SolidQueueMonitor::AuthenticationService).to receive(:authentication_required?).and_return(false)
    end

    describe 'GET #index' do
      let!(:failed_job1) { create(:solid_queue_failed_execution, created_at: 1.hour.ago) }
      let!(:failed_job2) { create(:solid_queue_failed_execution, created_at: 2.hours.ago) }

      it 'returns a successful response' do
        get :index
        expect(response).to be_successful
      end

      it 'assigns failed jobs ordered by created_at desc' do
        get :index
        expect(assigns(:failed_jobs)[:records]).to eq([failed_job1, failed_job2])
      end

      context 'with filters' do
        let!(:special_job) do
          job = create(:solid_queue_job, class_name: 'SpecialJob', queue_name: 'high_priority')
          create(:solid_queue_failed_execution, job: job)
        end

        it 'filters by class name' do
          get :index, params: { class_name: 'Special' }
          expect(assigns(:failed_jobs)[:records]).to eq([special_job])
        end

        it 'filters by queue name' do
          get :index, params: { queue_name: 'high' }
          expect(assigns(:failed_jobs)[:records]).to eq([special_job])
        end
      end

      context 'with pagination' do
        before do
          allow(SolidQueueMonitor).to receive(:jobs_per_page).and_return(1)
        end

        it 'paginates the results' do
          get :index, params: { page: 2 }
          expect(assigns(:failed_jobs)[:records]).to eq([failed_job2])
          expect(assigns(:failed_jobs)[:total_pages]).to eq(2)
          expect(assigns(:failed_jobs)[:current_page]).to eq(2)
        end
      end
    end

    describe 'POST #retry' do
      let!(:failed_job) { create(:solid_queue_failed_execution) }
      let(:service) { instance_double(SolidQueueMonitor::FailedJobService) }

      before do
        allow(SolidQueueMonitor::FailedJobService).to receive(:new).and_return(service)
      end

      context 'when retry is successful' do
        before do
          allow(service).to receive(:retry_job).with(failed_job.id.to_s).and_return(true)
        end

        it 'sets success flash message and redirects' do
          post :retry, params: { id: failed_job.id }

          expect(session[:flash_message]).to eq("Job #{failed_job.id} has been queued for retry.")
          expect(session[:flash_type]).to eq('success')
          expect(response).to redirect_to(failed_jobs_path)
        end

        it 'respects custom redirect path' do
          post :retry, params: { id: failed_job.id, redirect_to: '/custom/path' }
          expect(response).to redirect_to('/custom/path')
        end
      end

      context 'when retry fails' do
        before do
          allow(service).to receive(:retry_job).with(failed_job.id.to_s).and_return(false)
        end

        it 'sets error flash message and redirects' do
          post :retry, params: { id: failed_job.id }

          expect(session[:flash_message]).to eq("Failed to retry job #{failed_job.id}.")
          expect(session[:flash_type]).to eq('error')
          expect(response).to redirect_to(failed_jobs_path)
        end
      end
    end

    describe 'POST #discard' do
      let!(:failed_job) { create(:solid_queue_failed_execution) }
      let(:service) { instance_double(SolidQueueMonitor::FailedJobService) }

      before do
        allow(SolidQueueMonitor::FailedJobService).to receive(:new).and_return(service)
      end

      context 'when discard is successful' do
        before do
          allow(service).to receive(:discard_job).with(failed_job.id.to_s).and_return(true)
        end

        it 'sets success flash message and redirects' do
          post :discard, params: { id: failed_job.id }

          expect(session[:flash_message]).to eq("Job #{failed_job.id} has been discarded.")
          expect(session[:flash_type]).to eq('success')
          expect(response).to redirect_to(failed_jobs_path)
        end

        it 'respects custom redirect path' do
          post :discard, params: { id: failed_job.id, redirect_to: '/custom/path' }
          expect(response).to redirect_to('/custom/path')
        end
      end

      context 'when discard fails' do
        before do
          allow(service).to receive(:discard_job).with(failed_job.id.to_s).and_return(false)
        end

        it 'sets error flash message and redirects' do
          post :discard, params: { id: failed_job.id }

          expect(session[:flash_message]).to eq("Failed to discard job #{failed_job.id}.")
          expect(session[:flash_type]).to eq('error')
          expect(response).to redirect_to(failed_jobs_path)
        end
      end
    end

    describe 'POST #retry_all' do
      let(:job_ids) { %w[1 2 3] }
      let(:service) { instance_double(SolidQueueMonitor::FailedJobService) }

      before do
        allow(SolidQueueMonitor::FailedJobService).to receive(:new).and_return(service)
      end

      context 'when retry_all is successful' do
        before do
          allow(service).to receive(:retry_all).with(job_ids).and_return({ success: true, message: 'All jobs queued for retry' })
        end

        it 'sets success flash message and redirects' do
          post :retry_all, params: { job_ids: job_ids }

          expect(session[:flash_message]).to eq('All jobs queued for retry')
          expect(session[:flash_type]).to eq('success')
          expect(response).to redirect_to(failed_jobs_path)
        end
      end

      context 'when retry_all fails' do
        before do
          allow(service).to receive(:retry_all).with(job_ids).and_return({ success: false, message: 'Failed to retry jobs' })
        end

        it 'sets error flash message and redirects' do
          post :retry_all, params: { job_ids: job_ids }

          expect(session[:flash_message]).to eq('Failed to retry jobs')
          expect(session[:flash_type]).to eq('error')
          expect(response).to redirect_to(failed_jobs_path)
        end
      end
    end

    describe 'POST #discard_all' do
      let(:job_ids) { %w[1 2 3] }
      let(:service) { instance_double(SolidQueueMonitor::FailedJobService) }

      before do
        allow(SolidQueueMonitor::FailedJobService).to receive(:new).and_return(service)
      end

      context 'when discard_all is successful' do
        before do
          allow(service).to receive(:discard_all).with(job_ids).and_return({ success: true, message: 'All jobs discarded' })
        end

        it 'sets success flash message and redirects' do
          post :discard_all, params: { job_ids: job_ids }

          expect(session[:flash_message]).to eq('All jobs discarded')
          expect(session[:flash_type]).to eq('success')
          expect(response).to redirect_to(failed_jobs_path)
        end
      end

      context 'when discard_all fails' do
        before do
          allow(service).to receive(:discard_all).with(job_ids).and_return({ success: false, message: 'Failed to discard jobs' })
        end

        it 'sets error flash message and redirects' do
          post :discard_all, params: { job_ids: job_ids }

          expect(session[:flash_message]).to eq('Failed to discard jobs')
          expect(session[:flash_type]).to eq('error')
          expect(response).to redirect_to(failed_jobs_path)
        end
      end
    end

    context 'with authentication required' do
      before do
        allow(SolidQueueMonitor::AuthenticationService).to receive_messages(authentication_required?: true, authenticate: true)
      end

      it 'requires authentication for index' do
        get :index
        expect(response).to have_http_status(:unauthorized)
      end

      it 'allows access with valid credentials' do
        request.env['HTTP_AUTHORIZATION'] = valid_credentials
        get :index
        expect(response).to be_successful
      end
    end
  end
end
