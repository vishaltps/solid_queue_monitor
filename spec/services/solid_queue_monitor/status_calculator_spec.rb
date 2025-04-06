# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidQueueMonitor::StatusCalculator do
  describe '#calculate' do
    let(:job) { create(:solid_queue_job) }

    context 'when job is completed' do
      let(:completed_job) { create(:solid_queue_job, :completed) }

      it 'returns completed status' do
        calculator = described_class.new(completed_job)
        expect(calculator.calculate).to eq('completed')
      end
    end

    context 'when job has failed' do
      before do
        create(:solid_queue_failed_execution, job: job)
        job.define_singleton_method(:failed?) { true }
      end

      it 'returns failed status' do
        calculator = described_class.new(job)
        expect(calculator.calculate).to eq('failed')
      end
    end

    context 'when job is scheduled for the future' do
      before do
        job.scheduled_at = 1.hour.from_now
      end

      it 'returns scheduled status' do
        calculator = described_class.new(job)
        expect(calculator.calculate).to eq('scheduled')
      end
    end

    context 'when job is pending' do
      it 'returns pending status' do
        calculator = described_class.new(job)
        expect(calculator.calculate).to eq('pending')
      end
    end
  end
end
