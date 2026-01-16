# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidQueueMonitor::StatsPresenter do
  describe '#render' do
    subject { described_class.new(stats) }

    let(:stats) do
      {
        total_jobs: 100,
        scheduled: 20,
        ready: 30,
        in_progress: 15,
        recurring: 5,
        failed: 10,
        completed: 40
      }
    end

    it 'returns HTML string' do
      expect(subject.render).to be_a(String)
      expect(subject.render).to include('stats-container')
    end

    it 'includes all stats in the output' do
      html = subject.render

      expect(html).to include('Queue Statistics')
      expect(html).to include('Total Jobs')
      expect(html).to include('100')
      expect(html).to include('Scheduled')
      expect(html).to include('20')
      expect(html).to include('Ready')
      expect(html).to include('30')
      expect(html).to include('In Progress')
      expect(html).to include('15')
      expect(html).to include('Recurring')
      expect(html).to include('5')
      expect(html).to include('Failed')
      expect(html).to include('10')
      expect(html).to include('Completed')
      expect(html).to include('40')
    end
  end
end
