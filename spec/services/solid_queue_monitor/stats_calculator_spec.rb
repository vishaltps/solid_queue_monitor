# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidQueueMonitor::StatsCalculator do
  describe '.calculate' do
    before do
      create(:solid_queue_failed_execution)
      create(:solid_queue_scheduled_execution)
      create(:solid_queue_ready_execution)
      create(:solid_queue_claimed_execution)
      create(:solid_queue_blocked_execution)
    end

    it 'returns a hash with all required statistics' do
      stats = described_class.calculate

      expect(stats).to include(
        :active_jobs,
        :scheduled,
        :ready,
        :blocked,
        :failed,
        :in_progress,
        :recurring
      )
    end

    it 'calculates the correct counts from execution tables' do
      stats = described_class.calculate

      expect(stats[:scheduled]).to eq(1)
      expect(stats[:ready]).to eq(1)
      expect(stats[:blocked]).to eq(1)
      expect(stats[:failed]).to eq(1)
      expect(stats[:in_progress]).to eq(1)
      expect(stats[:recurring]).to eq(0)
    end

    it 'counts ready, scheduled, in-progress and blocked jobs as active' do
      stats = described_class.calculate

      expected_active = stats[:ready] + stats[:scheduled] + stats[:in_progress] + stats[:blocked]
      expect(stats[:active_jobs]).to eq(expected_active)
    end

    it 'does not count failed jobs as active' do
      expect { create(:solid_queue_failed_execution) }
        .not_to(change { described_class.calculate[:active_jobs] })
    end

    it 'does not query the jobs table for counts' do
      allow(SolidQueue::Job).to receive(:count).and_call_original
      described_class.calculate
      expect(SolidQueue::Job).not_to have_received(:count)
    end
  end
end
