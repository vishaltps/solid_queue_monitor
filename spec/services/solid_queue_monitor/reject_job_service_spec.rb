# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidQueueMonitor::RejectJobService do
  describe '#reject_many' do
    subject { described_class.new }

    let!(:scheduled_execution1) { create(:solid_queue_scheduled_execution) }
    let!(:scheduled_execution2) { create(:solid_queue_scheduled_execution) }

    it 'rejects scheduled jobs and marks them as finished' do
      expect do
        result = subject.reject_many([scheduled_execution1.id, scheduled_execution2.id])
        expect(result[:success]).to be true
      end.to change(SolidQueue::ScheduledExecution, :count).by(-2)
    end

    it 'marks associated jobs as finished when rejecting' do
      subject.reject_many([scheduled_execution1.id])

      job = scheduled_execution1.job.reload
      expect(job.finished_at).to be_present
    end

    it 'returns success message when all jobs are rejected successfully' do
      result = subject.reject_many([scheduled_execution1.id, scheduled_execution2.id])

      expect(result[:success]).to be true
      expect(result[:message]).to eq('All selected jobs have been rejected')
    end

    it 'handles non-existent job IDs gracefully' do
      result = subject.reject_many([999_999])

      expect(result[:success]).to be false
      expect(result[:message]).to eq('Failed to reject jobs')
    end

    it 'handles empty job IDs array gracefully' do
      result = subject.reject_many([])

      expect(result[:success]).to be false
      expect(result[:message]).to eq('No jobs selected')
    end

    it 'handles mix of valid and invalid job IDs' do
      result = subject.reject_many([scheduled_execution1.id, 999_999])

      expect(result[:success]).to be true
      expect(result[:message]).to include('1 jobs rejected, 1 failed')
    end

    it 'removes scheduled execution from database' do
      subject.reject_many([scheduled_execution1.id])

      expect(SolidQueue::ScheduledExecution.find_by(id: scheduled_execution1.id)).to be_nil
    end
  end

  describe '#call' do
    subject { described_class.new }

    let!(:scheduled_execution) { create(:solid_queue_scheduled_execution) }

    it 'rejects a single scheduled job' do
      expect do
        subject.call(scheduled_execution.id)
      end.to change(SolidQueue::ScheduledExecution, :count).by(-1)
    end

    it 'marks the job as finished' do
      subject.call(scheduled_execution.id)

      job = scheduled_execution.job.reload
      expect(job.finished_at).to be_present
    end
  end
end 