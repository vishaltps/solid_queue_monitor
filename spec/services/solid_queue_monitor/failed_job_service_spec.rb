# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidQueueMonitor::FailedJobService do
  subject(:service) { described_class.new }

  describe '#retry_job' do
    let(:job) { create(:solid_queue_job, queue_name: 'mailers', priority: 3) }
    let!(:failed_execution) { create(:solid_queue_failed_execution, job: job) }

    it 'moves the job to the ready queue and removes the failed execution' do
      result = service.retry_job(failed_execution.id)

      expect(result).to eq(success: true, message: 'Job queued for retry')
      expect(SolidQueue::FailedExecution.exists?(failed_execution.id)).to be(false)
      expect(SolidQueue::ReadyExecution.find_by(job_id: job.id))
        .to have_attributes(queue_name: 'mailers', priority: 3)
    end

    it "delegates to Solid Queue's FailedExecution#retry instead of creating the ready execution itself" do
      allow(SolidQueue::ReadyExecution).to receive(:create!)
      retried = []
      allow_any_instance_of(SolidQueue::FailedExecution).to receive(:retry) { |execution| retried << execution.id }

      service.retry_job(failed_execution.id)

      expect(retried).to eq([failed_execution.id])
      expect(SolidQueue::ReadyExecution).not_to have_received(:create!)
    end

    it 'reports a failed execution that no longer exists' do
      expect(service.retry_job(0)).to eq(success: false, message: 'Failed job not found')
    end

    it 'reports a failed execution removed after it was loaded' do
      allow(SolidQueue::FailedExecution).to receive(:find_by).and_wrap_original do |original, *args|
        original.call(*args).tap { |execution| SolidQueue::FailedExecution.where(id: execution.id).delete_all }
      end

      expect(service.retry_job(failed_execution.id)).to eq(success: false, message: 'Failed job not found')
      expect(SolidQueue::ReadyExecution.where(job_id: job.id)).to be_empty
    end

    it 'reports a failed execution whose job is gone' do
      SolidQueue::Job.where(id: job.id).delete_all

      expect(service.retry_job(failed_execution.id)).to eq(success: false, message: 'Associated job not found')
    end
  end

  describe '#retry_all' do
    let!(:first) { create(:solid_queue_failed_execution) }
    let!(:second) { create(:solid_queue_failed_execution) }

    it 'retries every selected job' do
      result = service.retry_all([first.id, second.id])

      expect(result).to eq(success: true, message: 'All selected jobs have been queued for retry')
      expect(SolidQueue::FailedExecution.count).to eq(0)
      expect(SolidQueue::ReadyExecution.pluck(:job_id)).to contain_exactly(first.job_id, second.job_id)
    end

    it 'counts jobs that could not be retried' do
      result = service.retry_all([first.id, 0])

      expect(result).to eq(success: true, message: '1 jobs queued for retry, 1 failed')
    end

    it 'counts a job whose retry raises as failed and still retries the rest' do
      allow(SolidQueue::FailedExecution).to receive(:find_by).and_call_original
      allow(SolidQueue::FailedExecution).to receive(:find_by).with(id: first.id)
                                                             .and_raise(ActiveRecord::LockWaitTimeout)

      result = service.retry_all([first.id, second.id])

      expect(result).to eq(success: true, message: '1 jobs queued for retry, 1 failed')
      expect(SolidQueue::ReadyExecution.pluck(:job_id)).to eq([second.job_id])
    end
  end
end
