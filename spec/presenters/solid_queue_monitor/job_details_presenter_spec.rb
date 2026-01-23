# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidQueueMonitor::JobDetailsPresenter do
  let(:job) { create(:solid_queue_job, class_name: 'TestJob', queue_name: 'default', priority: 5) }

  describe '#render' do
    subject(:rendered_html) { presenter.render }

    let(:presenter) { described_class.new(job, back_path: '/failed_jobs') }

    it 'renders the job details page container' do
      expect(rendered_html).to include('job-details-page')
    end

    it 'renders the job class name' do
      expect(rendered_html).to include('TestJob')
    end

    it 'renders the queue name' do
      expect(rendered_html).to include('default')
    end

    it 'renders the priority' do
      expect(rendered_html).to include('Priority')
    end

    it 'renders the back link' do
      expect(rendered_html).to include('href="/failed_jobs"')
      expect(rendered_html).to include('Back')
    end

    it 'renders the job arguments section' do
      expect(rendered_html).to include('Arguments')
    end

    it 'renders the job details section' do
      expect(rendered_html).to include('Job Details')
    end

    it 'renders the raw data section' do
      expect(rendered_html).to include('Raw Data')
    end

    context 'with a failed execution' do
      let(:failed_execution) do
        create(:solid_queue_failed_execution, job: job, error: { 'message' => 'Test error', 'backtrace' => %w[line1 line2] })
      end
      let(:presenter) { described_class.new(job, failed_execution: failed_execution, back_path: '/') }

      it 'renders the error section' do
        expect(rendered_html).to include('Error')
      end

      it 'renders retry and discard buttons' do
        expect(rendered_html).to include('Retry')
        expect(rendered_html).to include('Discard')
      end

      it 'renders the failed status badge' do
        expect(rendered_html).to include('Failed')
        expect(rendered_html).to include('status-failed')
      end
    end

    context 'with a claimed execution (in progress)' do
      let(:process) { create(:solid_queue_process, kind: 'Worker', hostname: 'worker-1', pid: 12_345) }
      let(:claimed_execution) do
        execution = create(:solid_queue_claimed_execution, job: job, process_id: process.id)
        execution.instance_variable_set(:@process, process)
        execution
      end
      let(:presenter) { described_class.new(job, claimed_execution: claimed_execution, back_path: '/') }

      it 'renders the worker section' do
        expect(rendered_html).to include('Worker')
      end

      it 'renders the hostname' do
        expect(rendered_html).to include('worker-1')
      end

      it 'renders the in progress status' do
        expect(rendered_html).to include('In Progress')
        expect(rendered_html).to include('status-in-progress')
      end
    end

    context 'with a scheduled execution' do
      let(:scheduled_at) { 1.hour.from_now }
      let(:scheduled_execution) { create(:solid_queue_scheduled_execution, job: job, scheduled_at: scheduled_at) }
      let(:presenter) { described_class.new(job, scheduled_execution: scheduled_execution, back_path: '/') }

      it 'renders the scheduled status' do
        expect(rendered_html).to include('Scheduled')
        expect(rendered_html).to include('status-scheduled')
      end
    end

    context 'with a completed job' do
      let(:completed_job) { create(:solid_queue_job, :completed, class_name: 'CompletedJob') }
      let(:presenter) { described_class.new(completed_job, back_path: '/') }

      it 'renders the completed status' do
        expect(rendered_html).to include('Completed')
        expect(rendered_html).to include('status-completed')
      end
    end

    context 'with recent executions' do
      let(:recent_jobs) do
        create_list(:solid_queue_job, 3, class_name: 'TestJob', finished_at: Time.current)
      end
      let(:presenter) { described_class.new(job, recent_executions: recent_jobs, back_path: '/') }

      it 'renders the recent executions section' do
        expect(rendered_html).to include('Recent Executions')
      end

      it 'renders the recent executions table' do
        expect(rendered_html).to include('recent-executions-table')
      end
    end
  end

  describe 'timing calculations' do
    context 'with start and end times' do
      let(:started_at) { 5.minutes.ago }
      let(:finished_at) { Time.current }
      let(:completed_job) { create(:solid_queue_job, created_at: 10.minutes.ago, finished_at: finished_at) }
      let(:claimed_execution) do
        execution = build(:solid_queue_claimed_execution, job: completed_job, created_at: started_at)
        execution.instance_variable_set(:@process, nil)
        execution
      end
      let(:presenter) { described_class.new(completed_job, claimed_execution: claimed_execution, back_path: '/') }

      it 'renders timing cards' do
        rendered_html = presenter.render
        expect(rendered_html).to include('timing-cards')
        expect(rendered_html).to include('Queue Wait')
        expect(rendered_html).to include('Execution')
        expect(rendered_html).to include('Total Time')
      end
    end
  end

  describe 'timeline rendering' do
    let(:completed_job) { create(:solid_queue_job, :completed, created_at: 10.minutes.ago) }
    let(:presenter) { described_class.new(completed_job, back_path: '/') }

    it 'renders the timeline section' do
      rendered_html = presenter.render
      expect(rendered_html).to include('Timeline')
      expect(rendered_html).to include('timeline-track')
    end
  end
end
