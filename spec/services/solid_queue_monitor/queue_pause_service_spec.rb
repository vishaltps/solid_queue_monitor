# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidQueueMonitor::QueuePauseService do
  describe '#pause' do
    subject { described_class.new(queue_name) }

    let(:queue_name) { 'default' }

    context 'when queue is not paused' do
      it 'pauses the queue successfully' do
        result = subject.pause

        expect(result[:success]).to be true
        expect(result[:message]).to eq("Queue 'default' has been paused")
        expect(SolidQueue::Pause.exists?(queue_name: queue_name)).to be true
      end
    end

    context 'when queue is already paused' do
      before do
        create(:solid_queue_pause, queue_name: queue_name)
      end

      it 'returns failure with appropriate message' do
        result = subject.pause

        expect(result[:success]).to be false
        expect(result[:message]).to eq("Queue 'default' is already paused")
      end
    end
  end

  describe '#resume' do
    subject { described_class.new(queue_name) }

    let(:queue_name) { 'default' }

    context 'when queue is paused' do
      before do
        create(:solid_queue_pause, queue_name: queue_name)
      end

      it 'resumes the queue successfully' do
        result = subject.resume

        expect(result[:success]).to be true
        expect(result[:message]).to eq("Queue 'default' has been resumed")
        expect(SolidQueue::Pause.exists?(queue_name: queue_name)).to be false
      end
    end

    context 'when queue is not paused' do
      it 'returns failure with appropriate message' do
        result = subject.resume

        expect(result[:success]).to be false
        expect(result[:message]).to eq("Queue 'default' is not paused")
      end
    end
  end

  describe '#paused?' do
    subject { described_class.new(queue_name) }

    let(:queue_name) { 'default' }

    context 'when queue is paused' do
      before do
        create(:solid_queue_pause, queue_name: queue_name)
      end

      it 'returns true' do
        expect(subject.paused?).to be true
      end
    end

    context 'when queue is not paused' do
      it 'returns false' do
        expect(subject.paused?).to be false
      end
    end
  end

  describe '.paused_queues' do
    before do
      create(:solid_queue_pause, queue_name: 'queue1')
      create(:solid_queue_pause, queue_name: 'queue2')
    end

    it 'returns array of paused queue names' do
      result = described_class.paused_queues

      expect(result).to be_an(Array)
      expect(result).to contain_exactly('queue1', 'queue2')
    end

    context 'when no queues are paused' do
      before do
        SolidQueue::Pause.destroy_all
      end

      it 'returns an empty array' do
        expect(described_class.paused_queues).to eq([])
      end
    end
  end
end
