# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidQueueMonitor::ExecuteJobService do
  describe '#execute_many' do
    subject { described_class.new }

    let!(:scheduled_execution1) { create(:solid_queue_scheduled_execution) }
    let!(:scheduled_execution2) { create(:solid_queue_scheduled_execution) }

    it 'moves scheduled jobs to ready queue' do
      expect do
        subject.execute_many([scheduled_execution1.id, scheduled_execution2.id])
      end.to change(SolidQueue::ReadyExecution, :count).by(2)
                                                       .and change(SolidQueue::ScheduledExecution, :count).by(-2)
    end

    it 'preserves job attributes when moving to ready queue' do
      subject.execute_many([scheduled_execution1.id])

      ready_execution = SolidQueue::ReadyExecution.last
      expect(ready_execution.job_id).to eq(scheduled_execution1.job_id)
      expect(ready_execution.queue_name).to eq(scheduled_execution1.queue_name)
      expect(ready_execution.priority).to eq(scheduled_execution1.priority)
    end

    it 'handles non-existent job IDs gracefully' do
      expect do
        subject.execute_many([999_999])
      end.not_to change(SolidQueue::ReadyExecution, :count)
    end

    it 'handles empty job IDs array gracefully' do
      expect do
        subject.execute_many([])
      end.not_to change(SolidQueue::ReadyExecution, :count)
    end
  end
end
