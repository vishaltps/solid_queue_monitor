# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidQueueMonitor::SearchResultsPresenter do
  subject { described_class.new(query, results) }

  let(:query) { 'TestJob' }
  let(:results) do
    {
      ready: [],
      scheduled: [],
      failed: [],
      in_progress: [],
      completed: [],
      recurring: []
    }
  end

  describe '#render' do
    it 'returns HTML content' do
      expect(subject.render).to be_a(String)
      expect(subject.render).to include('section-wrapper')
    end

    it 'includes the search query in the title' do
      expect(subject.render).to include('TestJob')
    end

    it 'does not include a duplicate search form (uses header search)' do
      html = subject.render
      expect(html).not_to include('name="q"')
    end

    context 'with empty results' do
      it 'shows no results message' do
        html = subject.render
        expect(html).to include('No results found')
      end

      it 'shows total count of 0' do
        html = subject.render
        expect(html).to include('0 results')
      end
    end

    context 'with ready job results' do
      let(:job) { create(:solid_queue_job, class_name: 'TestJobReady', queue_name: 'default') }
      let!(:ready_execution) { create(:solid_queue_ready_execution, job: job) }
      let(:results) do
        {
          ready: [ready_execution],
          scheduled: [],
          failed: [],
          in_progress: [],
          completed: [],
          recurring: []
        }
      end

      it 'shows the ready jobs section' do
        html = subject.render
        expect(html).to include('Ready Jobs')
        expect(html).to include('TestJobReady')
      end

      it 'includes a link to the job details' do
        html = subject.render
        expect(html).to include("jobs/#{job.id}")
      end

      it 'shows count of 1 result' do
        html = subject.render
        expect(html).to include('1 result')
      end
    end

    context 'with scheduled job results' do
      let(:job) { create(:solid_queue_job, class_name: 'TestJobScheduled') }
      let!(:scheduled_execution) { create(:solid_queue_scheduled_execution, job: job) }
      let(:results) do
        {
          ready: [],
          scheduled: [scheduled_execution],
          failed: [],
          in_progress: [],
          completed: [],
          recurring: []
        }
      end

      it 'shows the scheduled jobs section' do
        html = subject.render
        expect(html).to include('Scheduled Jobs')
        expect(html).to include('TestJobScheduled')
      end
    end

    context 'with failed job results' do
      let(:job) { create(:solid_queue_job, class_name: 'TestJobFailed') }
      let!(:failed_execution) { create(:solid_queue_failed_execution, job: job, error: 'Connection refused') }
      let(:results) do
        {
          ready: [],
          scheduled: [],
          failed: [failed_execution],
          in_progress: [],
          completed: [],
          recurring: []
        }
      end

      it 'shows the failed jobs section' do
        html = subject.render
        expect(html).to include('Failed Jobs')
        expect(html).to include('TestJobFailed')
      end

      it 'shows the error message' do
        html = subject.render
        expect(html).to include('Connection refused')
      end
    end

    context 'with in_progress job results' do
      let(:job) { create(:solid_queue_job, class_name: 'TestJobInProgress') }
      let!(:claimed_execution) { create(:solid_queue_claimed_execution, job: job) }
      let(:results) do
        {
          ready: [],
          scheduled: [],
          failed: [],
          in_progress: [claimed_execution],
          completed: [],
          recurring: []
        }
      end

      it 'shows the in progress jobs section' do
        html = subject.render
        expect(html).to include('In Progress Jobs')
        expect(html).to include('TestJobInProgress')
      end
    end

    context 'with completed job results' do
      let!(:completed_job) { create(:solid_queue_job, :completed, class_name: 'TestJobCompleted') }
      let(:results) do
        {
          ready: [],
          scheduled: [],
          failed: [],
          in_progress: [],
          completed: [completed_job],
          recurring: []
        }
      end

      it 'shows the completed jobs section' do
        html = subject.render
        expect(html).to include('Completed Jobs')
        expect(html).to include('TestJobCompleted')
      end

      it 'includes a link to the job details' do
        html = subject.render
        expect(html).to include("jobs/#{completed_job.id}")
      end
    end

    context 'with recurring task results' do
      let!(:recurring_task) { create(:solid_queue_recurring_task, key: 'test_cleanup', class_name: 'TestCleanupJob') }
      let(:results) do
        {
          ready: [],
          scheduled: [],
          failed: [],
          in_progress: [],
          completed: [],
          recurring: [recurring_task]
        }
      end

      it 'shows the recurring tasks section' do
        html = subject.render
        expect(html).to include('Recurring Tasks')
        expect(html).to include('test_cleanup')
      end
    end

    context 'with results across multiple categories' do
      let(:ready_job) { create(:solid_queue_job, class_name: 'TestReadyJob') }
      let(:failed_job) { create(:solid_queue_job, class_name: 'TestFailedJob') }
      let!(:ready_execution) { create(:solid_queue_ready_execution, job: ready_job) }
      let!(:failed_execution) { create(:solid_queue_failed_execution, job: failed_job) }
      let(:results) do
        {
          ready: [ready_execution],
          scheduled: [],
          failed: [failed_execution],
          in_progress: [],
          completed: [],
          recurring: []
        }
      end

      it 'shows total count across all categories' do
        html = subject.render
        expect(html).to include('2 results')
      end

      it 'shows both sections' do
        html = subject.render
        expect(html).to include('Ready Jobs')
        expect(html).to include('Failed Jobs')
      end
    end

    context 'with blank query' do
      let(:query) { '' }

      it 'shows appropriate message' do
        html = subject.render
        expect(html).to include('Enter a search term')
      end
    end
  end
end
