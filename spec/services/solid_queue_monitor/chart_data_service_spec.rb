# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/VerifiedDoubles
RSpec.describe SolidQueueMonitor::ChartDataService do
  describe '#calculate' do
    let(:service) { described_class.new(time_range: time_range) }
    let(:time_range) { '1d' }

    before do
      # Mock the created_at query chain
      created_relation = double('created_relation')
      allow(created_relation).to receive(:pluck).with(:created_at).and_return([])
      allow(SolidQueue::Job).to receive(:where).with(created_at: anything).and_return(created_relation)

      # Mock the finished_at query chain (where.where.not.pluck)
      completed_relation = double('completed_relation')
      completed_not_relation = double('completed_not_relation')
      allow(completed_relation).to receive(:where).and_return(completed_not_relation)
      allow(completed_not_relation).to receive(:not).and_return(completed_not_relation)
      allow(completed_not_relation).to receive(:pluck).with(:finished_at).and_return([])
      allow(SolidQueue::Job).to receive(:where).with(finished_at: anything).and_return(completed_relation)

      # Mock the failed executions query
      failed_relation = double('failed_relation')
      allow(failed_relation).to receive(:pluck).with(:created_at).and_return([])
      allow(SolidQueue::FailedExecution).to receive(:where).with(created_at: anything).and_return(failed_relation)
    end

    it 'returns chart data structure' do
      result = service.calculate

      expect(result).to include(
        :labels,
        :created,
        :completed,
        :failed,
        :totals,
        :time_range,
        :time_range_label,
        :available_ranges
      )
    end

    it 'returns correct number of buckets for 1d range' do
      result = service.calculate

      expect(result[:labels].size).to eq(24)
      expect(result[:created].size).to eq(24)
      expect(result[:completed].size).to eq(24)
      expect(result[:failed].size).to eq(24)
    end

    it 'returns the current time range' do
      result = service.calculate

      expect(result[:time_range]).to eq('1d')
    end

    it 'returns all available time ranges with labels' do
      result = service.calculate

      expect(result[:available_ranges].keys).to eq(%w[15m 30m 1h 3h 6h 12h 1d 3d 1w])
    end

    context 'with 1h time range' do
      let(:time_range) { '1h' }

      it 'returns 12 buckets' do
        result = service.calculate

        expect(result[:labels].size).to eq(12)
      end
    end

    context 'with 1w time range' do
      let(:time_range) { '1w' }

      it 'returns 28 buckets' do
        result = service.calculate

        expect(result[:labels].size).to eq(28)
      end
    end

    context 'with invalid time range' do
      let(:time_range) { 'invalid' }

      it 'defaults to 1d' do
        result = service.calculate

        expect(result[:time_range]).to eq('1d')
        expect(result[:labels].size).to eq(24)
      end
    end

    context 'with job data' do
      let(:now) { Time.current }
      let(:created_timestamps) { [now - 30.minutes, now - 45.minutes] }
      let(:completed_timestamps) { [now - 20.minutes] }
      let(:failed_timestamps) { [now - 10.minutes, now - 15.minutes] }

      before do
        # Override mocks with actual data
        created_relation = double('created_relation')
        allow(created_relation).to receive(:pluck).with(:created_at).and_return(created_timestamps)
        allow(SolidQueue::Job).to receive(:where).with(created_at: anything).and_return(created_relation)

        completed_relation = double('completed_relation')
        completed_not_relation = double('completed_not_relation')
        allow(completed_relation).to receive(:where).and_return(completed_not_relation)
        allow(completed_not_relation).to receive(:not).and_return(completed_not_relation)
        allow(completed_not_relation).to receive(:pluck).with(:finished_at).and_return(completed_timestamps)
        allow(SolidQueue::Job).to receive(:where).with(finished_at: anything).and_return(completed_relation)

        failed_relation = double('failed_relation')
        allow(failed_relation).to receive(:pluck).with(:created_at).and_return(failed_timestamps)
        allow(SolidQueue::FailedExecution).to receive(:where).with(created_at: anything).and_return(failed_relation)
      end

      it 'aggregates job counts into buckets' do
        result = service.calculate

        total_created = result[:created].sum
        total_completed = result[:completed].sum
        total_failed = result[:failed].sum

        expect(total_created).to eq(2)
        expect(total_completed).to eq(1)
        expect(total_failed).to eq(2)
      end
    end
  end

  describe 'TIME_RANGES' do
    it 'defines all expected time ranges' do
      expect(described_class::TIME_RANGES.keys).to eq(%w[15m 30m 1h 3h 6h 12h 1d 3d 1w])
    end

    it 'has duration, buckets, label_format, and label for each range' do
      described_class::TIME_RANGES.each do |key, config|
        expect(config).to include(:duration, :buckets, :label_format, :label),
                          "Expected #{key} to have duration, buckets, label_format, and label"
      end
    end
  end

  describe 'DEFAULT_TIME_RANGE' do
    it 'is 1d' do
      expect(described_class::DEFAULT_TIME_RANGE).to eq('1d')
    end
  end
end
# rubocop:enable RSpec/VerifiedDoubles
