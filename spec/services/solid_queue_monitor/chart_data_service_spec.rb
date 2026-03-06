# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidQueueMonitor::ChartDataService do
  describe '#calculate' do
    let(:service) { described_class.new(time_range: time_range) }
    let(:time_range) { '1d' }

    context 'with no data' do
      it 'returns the required keys' do
        result = service.calculate
        expect(result).to include(:labels, :created, :completed, :failed,
                                  :totals, :time_range, :time_range_label, :available_ranges)
      end

      it 'returns correct bucket count for 1d' do
        result = service.calculate
        expect(result[:labels].size).to eq(24)
        expect(result[:created].size).to eq(24)
        expect(result[:completed].size).to eq(24)
        expect(result[:failed].size).to eq(24)
      end

      it 'returns all zeros' do
        result = service.calculate
        expect(result[:totals]).to eq({ created: 0, completed: 0, failed: 0 })
      end

      it 'returns the current time range' do
        expect(service.calculate[:time_range]).to eq('1d')
      end

      it 'returns all available time ranges' do
        expect(service.calculate[:available_ranges].keys).to eq(%w[15m 30m 1h 3h 6h 12h 1d 3d 1w])
      end
    end

    context 'with 1h time range' do
      let(:time_range) { '1h' }
      it('returns 12 buckets') { expect(service.calculate[:labels].size).to eq(12) }
    end

    context 'with 1w time range' do
      let(:time_range) { '1w' }
      it('returns 28 buckets') { expect(service.calculate[:labels].size).to eq(28) }
    end

    context 'with invalid time range' do
      let(:time_range) { 'invalid' }

      it 'defaults to 1d with 24 buckets' do
        result = service.calculate
        expect(result[:time_range]).to eq('1d')
        expect(result[:labels].size).to eq(24)
      end
    end

    context 'with jobs in the time window' do
      let(:time_range) { '1h' }

      before do
        now = Time.current
        create(:solid_queue_job, created_at: now - 10.minutes)
        create(:solid_queue_job, created_at: now - 10.minutes)
        create(:solid_queue_job, :completed,
               created_at: now - 25.minutes, finished_at: now - 20.minutes)
        create(:solid_queue_failed_execution, created_at: now - 15.minutes)
      end

      it 'counts created jobs' do
        # At least 2 regular + 1 completed + 1 from failed execution factory
        expect(service.calculate[:created].sum).to be >= 2
      end

      it 'counts completed jobs' do
        expect(service.calculate[:completed].sum).to eq(1)
      end

      it 'counts failed executions' do
        expect(service.calculate[:failed].sum).to eq(1)
      end

      it 'totals match bucket sums' do
        result = service.calculate
        expect(result[:totals][:created]).to eq(result[:created].sum)
        expect(result[:totals][:completed]).to eq(result[:completed].sum)
        expect(result[:totals][:failed]).to eq(result[:failed].sum)
      end
    end

    context 'with jobs outside the window' do
      let(:time_range) { '1h' }
      before { create(:solid_queue_job, created_at: 2.hours.ago) }

      it 'excludes them' do
        expect(service.calculate[:created].sum).to eq(0)
      end
    end
  end

  describe 'constants' do
    it 'defines all time ranges' do
      expect(described_class::TIME_RANGES.keys).to eq(%w[15m 30m 1h 3h 6h 12h 1d 3d 1w])
    end

    it 'has required config per range' do
      described_class::TIME_RANGES.each_value do |config|
        expect(config).to include(:duration, :buckets, :label_format, :label)
      end
    end

    it 'defaults to 1d' do
      expect(described_class::DEFAULT_TIME_RANGE).to eq('1d')
    end
  end
end
