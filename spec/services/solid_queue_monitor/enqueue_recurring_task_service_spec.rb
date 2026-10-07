# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidQueueMonitor::EnqueueRecurringTaskService do
  describe '.call' do
    let(:recurring_task) do
      create(:solid_queue_recurring_task,
             key: 'hourly_metrics',
             class_name: 'SolidQueueMonitorEnqueueProbeJob',
             queue_name: 'metrics',
             priority: 3)
    end

    context 'when the task exists' do
      before { recurring_task }

      it 'enqueues the recurring task into the ready queue' do
        result = nil

        expect do
          result = described_class.call(recurring_task.id)
        end.to change(SolidQueue::ReadyExecution, :count).by(1)

        expect(result[:success]).to be(true)
        expect(result[:message]).to include('hourly_metrics')

        ready_execution = SolidQueue::ReadyExecution.last
        expect(ready_execution.queue_name).to eq('metrics')
        expect(ready_execution.priority).to eq(3)
        expect(ready_execution.job.class_name).to eq('SolidQueueMonitorEnqueueProbeJob')
      end

      it 'returns an error when enqueue fails' do
        task = SolidQueue::RecurringTask.find(recurring_task.id)
        allow(SolidQueue::RecurringTask).to receive(:find).and_return(task)
        allow(task).to receive(:enqueue).and_raise(StandardError, 'missing job class')

        result = described_class.call(recurring_task.id)

        expect(result[:success]).to be(false)
        expect(result[:message]).to include('missing job class')
      end
    end

    it 'returns an error when the task does not exist' do
      result = described_class.call(0)

      expect(result[:success]).to be(false)
      expect(result[:message]).to eq('Recurring task not found')
    end
  end
end
