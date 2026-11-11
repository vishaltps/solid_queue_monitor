# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidQueueMonitor::DiscardReadyJobService do
  describe '#call' do
    subject { described_class.new }

    let!(:ready_execution) { create(:solid_queue_ready_execution) }

    it 'discards a single ready job' do
      result = nil
      expect { result = subject.call(ready_execution.id) }.to change(SolidQueue::ReadyExecution, :count).by(-1)

      expect(result).to be true
      expect(ready_execution.job.reload.finished_at).to be_present
    end

    it 'reports a job that is no longer ready' do
      result = subject.call(999_999)

      expect(result).to be false
    end

    it 'removes a ready execution whose job row is gone' do
      allow(SolidQueue::Job).to receive(:find_by).with(id: ready_execution.job_id).and_return(nil)

      result = nil
      expect { result = subject.call(ready_execution.id) }.to change(SolidQueue::ReadyExecution, :count).by(-1)
      expect(result).to be true
    end

    it 'does not mark the job finished when a worker deleted the ready execution first' do
      relation = instance_double(ActiveRecord::Relation, delete_all: 0)
      allow(SolidQueue::ReadyExecution).to receive(:where).with(id: ready_execution.id).and_return(relation)

      expect(subject.call(ready_execution.id)).to be false
      expect(ready_execution.job.reload.finished_at).to be_nil
    end

    context 'with a concurrency-limited job' do
      let(:job) { ready_execution.job }
      let(:released) { [] }

      before do
        released_ids = released
        job.define_singleton_method(:concurrency_limited?) { true }
        job.define_singleton_method(:unblock_next_blocked_job) { released_ids << id }
        allow(SolidQueue::Job).to receive(:find_by).with(id: job.id).and_return(job)
      end

      it 'gives back the concurrency slot' do
        stub_const('TestJob', Class.new)

        subject.call(ready_execution.id)

        expect(released).to eq([job.id])
      end

      it 'frees the slot by key when its class no longer exists' do
        allow(SolidQueue::Job).to receive(:release_all_concurrency_locks)

        expect(subject.call(ready_execution.id)).to be true
        expect(released).to be_empty
        expect(SolidQueue::Job).to have_received(:release_all_concurrency_locks).with([job])
        expect(job.reload.finished_at).to be_present
      end
    end
  end

  describe '#discard_many' do
    subject { described_class.new }

    let!(:ready_execution1) { create(:solid_queue_ready_execution) }
    let!(:ready_execution2) { create(:solid_queue_ready_execution) }

    it 'removes the ready executions' do
      expect do
        result = subject.discard_many([ready_execution1.id, ready_execution2.id])
        expect(result[:success]).to be true
      end.to change(SolidQueue::ReadyExecution, :count).by(-2)
    end

    it 'marks the associated jobs as finished' do
      subject.discard_many([ready_execution1.id])

      expect(ready_execution1.job.reload.finished_at).to be_present
    end

    it 'leaves unselected jobs ready' do
      subject.discard_many([ready_execution1.id])

      expect(SolidQueue::ReadyExecution.find_by(id: ready_execution2.id)).to be_present
      expect(ready_execution2.job.reload.finished_at).to be_nil
    end

    it 'returns success message when all jobs are discarded' do
      result = subject.discard_many([ready_execution1.id, ready_execution2.id])

      expect(result[:message]).to eq('All selected jobs have been discarded')
    end

    it 'counts a job no longer ready (e.g. claimed by a worker) as failed' do
      result = subject.discard_many([999_999])

      expect(result[:success]).to be false
      expect(result[:message]).to eq('Failed to discard jobs')
    end

    it 'accepts a single id that is not wrapped in an array' do
      result = subject.discard_many(ready_execution1.id.to_s)

      expect(result[:message]).to eq('All selected jobs have been discarded')
      expect(SolidQueue::ReadyExecution.find_by(id: ready_execution1.id)).to be_nil
    end

    it 'handles empty job IDs gracefully' do
      result = subject.discard_many([])

      expect(result[:success]).to be false
      expect(result[:message]).to eq('No jobs selected')
    end

    it 'handles mix of valid and invalid job IDs' do
      result = subject.discard_many([ready_execution1.id, 999_999])

      expect(result[:success]).to be true
      expect(result[:message]).to eq('1 jobs discarded, 1 failed')
    end
  end
end
