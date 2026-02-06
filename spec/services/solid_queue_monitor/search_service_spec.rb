# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidQueueMonitor::SearchService do
  describe '#search' do
    subject { described_class.new(query).search }

    context 'with blank query' do
      let(:query) { '' }

      it 'returns empty results for all categories' do
        expect(subject).to eq({
          ready: [],
          scheduled: [],
          failed: [],
          in_progress: [],
          completed: [],
          recurring: []
        })
      end
    end

    context 'with nil query' do
      let(:query) { nil }

      it 'returns empty results for all categories' do
        expect(subject).to eq({
          ready: [],
          scheduled: [],
          failed: [],
          in_progress: [],
          completed: [],
          recurring: []
        })
      end
    end

    context 'searching by class_name' do
      let(:query) { 'UserMailer' }
      let!(:matching_job) { create(:solid_queue_job, class_name: 'UserMailerJob') }
      let!(:non_matching_job) { create(:solid_queue_job, class_name: 'OrderProcessor') }
      let!(:ready_execution) { create(:solid_queue_ready_execution, job: matching_job) }

      it 'returns matching ready jobs' do
        expect(subject[:ready].map(&:job)).to include(matching_job)
        expect(subject[:ready].map(&:job)).not_to include(non_matching_job)
      end
    end

    context 'searching by queue_name' do
      let(:query) { 'mailers' }
      let!(:matching_job) { create(:solid_queue_job, queue_name: 'mailers') }
      let!(:non_matching_job) { create(:solid_queue_job, queue_name: 'default') }
      let!(:ready_execution) { create(:solid_queue_ready_execution, job: matching_job) }

      it 'returns matching ready jobs' do
        expect(subject[:ready].map(&:job)).to include(matching_job)
        expect(subject[:ready].map(&:job)).not_to include(non_matching_job)
      end
    end

    context 'searching by arguments' do
      let(:query) { 'user@example.com' }
      let!(:matching_job) { create(:solid_queue_job, arguments: '["user@example.com"]') }
      let!(:non_matching_job) { create(:solid_queue_job, arguments: '["other@test.com"]') }
      let!(:ready_execution) { create(:solid_queue_ready_execution, job: matching_job) }

      it 'returns matching ready jobs' do
        expect(subject[:ready].map(&:job)).to include(matching_job)
        expect(subject[:ready].map(&:job)).not_to include(non_matching_job)
      end
    end

    context 'searching by active_job_id' do
      let(:job_id) { 'abc-123-def-456' }
      let(:query) { 'abc-123' }
      let!(:matching_job) { create(:solid_queue_job, active_job_id: job_id) }
      let!(:non_matching_job) { create(:solid_queue_job, active_job_id: 'xyz-789') }
      let!(:ready_execution) { create(:solid_queue_ready_execution, job: matching_job) }

      it 'returns matching ready jobs' do
        expect(subject[:ready].map(&:job)).to include(matching_job)
        expect(subject[:ready].map(&:job)).not_to include(non_matching_job)
      end
    end

    context 'searching scheduled jobs' do
      let(:query) { 'ScheduledTask' }
      let!(:job) { create(:solid_queue_job, class_name: 'ScheduledTaskJob') }
      let!(:scheduled_execution) { create(:solid_queue_scheduled_execution, job: job) }

      it 'returns matching scheduled jobs' do
        expect(subject[:scheduled].map(&:job)).to include(job)
      end
    end

    context 'searching failed jobs by error message' do
      let(:query) { 'Connection refused' }
      let!(:job) { create(:solid_queue_job, class_name: 'SomeJob') }
      let!(:failed_execution) { create(:solid_queue_failed_execution, job: job, error: 'Error: Connection refused to host') }

      it 'returns matching failed jobs' do
        expect(subject[:failed].map(&:job)).to include(job)
      end
    end

    context 'searching failed jobs by class_name' do
      let(:query) { 'FailingJob' }
      let!(:job) { create(:solid_queue_job, class_name: 'FailingJobProcessor') }
      let!(:failed_execution) { create(:solid_queue_failed_execution, job: job) }

      it 'returns matching failed jobs' do
        expect(subject[:failed].map(&:job)).to include(job)
      end
    end

    context 'searching in_progress jobs' do
      let(:query) { 'ProcessingJob' }
      let!(:job) { create(:solid_queue_job, class_name: 'ProcessingJobWorker') }
      let!(:claimed_execution) { create(:solid_queue_claimed_execution, job: job) }

      it 'returns matching in_progress jobs' do
        expect(subject[:in_progress].map(&:job)).to include(job)
      end
    end

    context 'searching completed jobs' do
      let(:query) { 'CompletedTask' }
      let!(:completed_job) { create(:solid_queue_job, :completed, class_name: 'CompletedTaskJob') }
      let!(:non_completed_job) { create(:solid_queue_job, class_name: 'CompletedTaskPending') }

      it 'returns matching completed jobs' do
        expect(subject[:completed]).to include(completed_job)
      end

      it 'does not include non-completed jobs' do
        expect(subject[:completed]).not_to include(non_completed_job)
      end
    end

    context 'searching completed jobs by active_job_id' do
      let(:job_id) { '9b00ebba-0448-438d-8af2-79c5aae3d204' }
      let(:query) { job_id }
      let!(:completed_job) { create(:solid_queue_job, :completed, active_job_id: job_id) }

      it 'returns matching completed jobs by job ID' do
        expect(subject[:completed]).to include(completed_job)
      end
    end

    context 'searching completed jobs by arguments' do
      let(:query) { 'order_123' }
      let!(:completed_job) { create(:solid_queue_job, :completed, arguments: '{"order_id":"order_123"}') }

      it 'returns matching completed jobs by arguments' do
        expect(subject[:completed]).to include(completed_job)
      end
    end

    context 'searching recurring tasks by key' do
      let(:query) { 'daily_cleanup' }
      let!(:recurring_task) { create(:solid_queue_recurring_task, key: 'daily_cleanup_task') }

      it 'returns matching recurring tasks' do
        expect(subject[:recurring]).to include(recurring_task)
      end
    end

    context 'searching recurring tasks by class_name' do
      let(:query) { 'CleanupJob' }
      let!(:recurring_task) { create(:solid_queue_recurring_task, class_name: 'CleanupJobWorker') }

      it 'returns matching recurring tasks' do
        expect(subject[:recurring]).to include(recurring_task)
      end
    end

    context 'case insensitive search' do
      let(:query) { 'usermailer' }
      let!(:job) { create(:solid_queue_job, class_name: 'UserMailerJob') }
      let!(:ready_execution) { create(:solid_queue_ready_execution, job: job) }

      it 'matches regardless of case' do
        expect(subject[:ready].map(&:job)).to include(job)
      end
    end

    context 'with results across multiple categories' do
      let(:query) { 'TestJob' }
      let!(:ready_job) { create(:solid_queue_job, class_name: 'TestJobReady') }
      let!(:scheduled_job) { create(:solid_queue_job, class_name: 'TestJobScheduled') }
      let!(:failed_job) { create(:solid_queue_job, class_name: 'TestJobFailed') }
      let!(:ready_execution) { create(:solid_queue_ready_execution, job: ready_job) }
      let!(:scheduled_execution) { create(:solid_queue_scheduled_execution, job: scheduled_job) }
      let!(:failed_execution) { create(:solid_queue_failed_execution, job: failed_job) }

      it 'returns results in all matching categories' do
        expect(subject[:ready].map(&:job)).to include(ready_job)
        expect(subject[:scheduled].map(&:job)).to include(scheduled_job)
        expect(subject[:failed].map(&:job)).to include(failed_job)
      end
    end

    context 'result limits' do
      let(:query) { 'BulkJob' }

      before do
        30.times do |i|
          job = create(:solid_queue_job, class_name: "BulkJob#{i}")
          create(:solid_queue_ready_execution, job: job)
        end
      end

      it 'limits results to 25 per category' do
        expect(subject[:ready].size).to eq(25)
      end
    end

    context 'with no matching results' do
      let(:query) { 'NonExistentJobClassName' }
      let!(:job) { create(:solid_queue_job, class_name: 'SomeOtherJob') }
      let!(:ready_execution) { create(:solid_queue_ready_execution, job: job) }

      it 'returns empty arrays for all categories' do
        expect(subject[:ready]).to be_empty
        expect(subject[:scheduled]).to be_empty
        expect(subject[:failed]).to be_empty
        expect(subject[:in_progress]).to be_empty
        expect(subject[:completed]).to be_empty
        expect(subject[:recurring]).to be_empty
      end
    end

    context 'SQL injection prevention' do
      let(:query) { "'; DROP TABLE solid_queue_jobs; --" }

      it 'safely handles malicious input' do
        expect { subject }.not_to raise_error
      end
    end
  end
end
