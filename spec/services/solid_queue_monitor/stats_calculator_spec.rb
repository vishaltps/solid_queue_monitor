require 'spec_helper'

RSpec.describe SolidQueueMonitor::StatsCalculator do
  describe '.calculate' do
    before do
      # Create some test data
      create_list(:solid_queue_job, 3)
      create(:solid_queue_job, :completed)
      create(:solid_queue_job, :completed)
      create(:solid_queue_job, queue_name: 'high_priority')
      create(:solid_queue_failed_execution)
      create(:solid_queue_scheduled_execution)
      create(:solid_queue_ready_execution)
    end
    
    it 'returns a hash with all required statistics' do
      stats = described_class.calculate
      
      expect(stats).to be_a(Hash)
      expect(stats).to include(
        :total_jobs,
        :unique_queues,
        :scheduled,
        :ready,
        :failed,
        :completed
      )
    end
    
    it 'calculates the correct counts' do
      stats = described_class.calculate
      
      expect(stats[:total_jobs]).to eq(6)
      expect(stats[:unique_queues]).to eq(2)
      expect(stats[:scheduled]).to eq(1)
      expect(stats[:ready]).to eq(1)
      expect(stats[:failed]).to eq(1)
      expect(stats[:completed]).to eq(2)
    end
  end
end 