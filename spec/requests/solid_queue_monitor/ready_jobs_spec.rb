# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Ready Jobs' do
  describe 'GET /ready_jobs' do
    let!(:ready_job1) { create(:solid_queue_ready_execution, created_at: 1.hour.ago) }
    let!(:ready_job2) { create(:solid_queue_ready_execution, created_at: 2.hours.ago) }

    it 'returns a successful response' do
      get '/ready_jobs'

      expect(response).to have_http_status(:ok)
    end

    it 'displays the page title' do
      get '/ready_jobs'

      expect(response.body).to include('Ready Jobs')
    end

    it 'displays the ready jobs' do
      get '/ready_jobs'

      expect(response.body).to include(ready_job1.job.class_name)
    end

    context 'with no ready jobs' do
      before do
        SolidQueue::ReadyExecution.delete_all
      end

      it 'still returns a successful response' do
        get '/ready_jobs'

        expect(response).to have_http_status(:ok)
      end
    end

    context 'with class_name filter' do
      let(:special_job) { create(:solid_queue_job, class_name: 'SpecialReadyJob') }
      let!(:special_ready) { create(:solid_queue_ready_execution, job: special_job) }

      it 'filters by class name' do
        get '/ready_jobs', params: { class_name: 'Special' }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('SpecialReadyJob')
      end
    end

    context 'with queue_name filter' do
      let(:queue_job) { create(:solid_queue_job, queue_name: 'priority_lane') }
      let!(:queue_ready) { create(:solid_queue_ready_execution, job: queue_job, queue_name: 'priority_lane') }

      it 'filters by queue name' do
        get '/ready_jobs', params: { queue_name: 'priority_lane' }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('priority_lane')
      end
    end

    it 'renders the bulk discard controls with the form kept out of the table' do
      get '/ready_jobs'

      doc = Nokogiri::HTML5(response.body)
      expect(doc.at_css('#discard-ready-selected-top')['data-action-url']).to eq('/discard_ready_jobs')
      expect(doc.css('.ready-job-checkbox').map { |box| box['value'] }).to include(ready_job1.id.to_s)
      expect(doc.at_css('#ready-jobs-form')).to be_present
      expect(doc.at_css('#ready-jobs-form table')).to be_nil
    end
  end

  describe 'row actions on GET /ready_jobs' do
    let!(:ready_job) { create(:solid_queue_ready_execution) }

    it 'submits the row Discard to its own action' do
      get '/ready_jobs'

      doc = Nokogiri::HTML5(response.body)
      discard_form = doc.at_xpath("//button[normalize-space()='Discard']/ancestor::form[1]")

      expect(discard_form['action']).to eq("/discard_ready_job/#{ready_job.id}")
    end
  end

  describe 'POST /discard_ready_job/:id' do
    let!(:ready_job) { create(:solid_queue_ready_execution) }

    it 'discards the job and redirects' do
      expect do
        post "/discard_ready_job/#{ready_job.id}"
      end.to change(SolidQueue::ReadyExecution, :count).by(-1)

      expect(response).to redirect_to('/ready_jobs')
    end

    it 'redirects with an error instead of failing when the discard raises' do
      allow_any_instance_of(SolidQueueMonitor::DiscardReadyJobService)
        .to receive(:call).and_raise(ActiveRecord::LockWaitTimeout, 'lock timeout')

      post "/discard_ready_job/#{ready_job.id}"

      expect(response).to redirect_to('/ready_jobs')
    end

    it 'redirects with an error when the job is no longer ready' do
      post '/discard_ready_job/999999'

      expect(response).to redirect_to('/ready_jobs')
      expect(SolidQueue::ReadyExecution.count).to eq(1)
    end
  end

  describe 'POST /discard_ready_jobs' do
    let!(:ready_job1) { create(:solid_queue_ready_execution) }
    let!(:ready_job2) { create(:solid_queue_ready_execution) }

    it 'discards the selected jobs and redirects' do
      expect do
        post '/discard_ready_jobs', params: { job_ids: [ready_job1.id, ready_job2.id] }
      end.to change(SolidQueue::ReadyExecution, :count).by(-2)

      expect(response).to redirect_to('/ready_jobs')
    end

    it 'accepts a single job_ids value without brackets' do
      expect do
        post '/discard_ready_jobs', params: { job_ids: ready_job1.id.to_s }
      end.to change(SolidQueue::ReadyExecution, :count).by(-1)
    end

    it 'handles empty job_ids gracefully' do
      post '/discard_ready_jobs', params: { job_ids: [] }

      expect(response).to redirect_to('/ready_jobs')
      expect(SolidQueue::ReadyExecution.count).to eq(2)
    end
  end
end
