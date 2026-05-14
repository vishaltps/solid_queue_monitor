# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidQueueMonitor::ChartDataService do
  include ActiveSupport::Testing::TimeHelpers

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

    context 'when the host application configures a non-UTC time zone' do
      # 2026-05-13 17:00 UTC == 2026-05-13 10:00 America/Los_Angeles (PDT).
      let(:frozen_utc) { Time.utc(2026, 5, 13, 17, 0, 0) }

      around { |example| Time.use_zone('America/Los_Angeles') { example.run } }
      before { travel_to(frozen_utc) }

      it 'formats 1d x-axis labels in the host time zone' do
        labels = described_class.new(time_range: '1d').calculate[:labels]
        # 24 hourly buckets walking forward from (now - 1 day) at 10:00 PT
        # back to now at 09:00 PT (23 hours later).
        expect(labels.first).to eq('10:00')
        expect(labels.last).to eq('09:00')
      end

      it 'does not format 1d labels in UTC' do
        labels = described_class.new(time_range: '1d').calculate[:labels]
        # In UTC the same range would start at 17:00 and end at 16:00.
        expect(labels.first).not_to eq('17:00')
        expect(labels.last).not_to eq('16:00')
      end

      it 'formats fine-grained 1h labels in the host time zone' do
        labels = described_class.new(time_range: '1h').calculate[:labels]
        # 12 buckets, 5 minutes each, walking from 09:00 PT to 09:55 PT.
        expect(labels.first).to eq('09:00')
        expect(labels.last).to eq('09:55')
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
