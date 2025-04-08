# frozen_string_literal: true

require 'spec_helper'

# Mock SolidQueue models for testing
module SolidQueue
  class Job
    def self.count
      10
    end

    def self.where(_conditions)
      self
    end

    def self.joins(_table)
      self
    end
  end

  class ReadyExecution
    def self.count
      5
    end
  end

  class ScheduledExecution
    def self.count
      2
    end
  end

  class FailedExecution
    def self.count
      1
    end
  end

  class Execution
    def self.count
      2
    end
  end
end

# Mock SolidQueueMonitor::StatsCalculator
module SolidQueueMonitor
  class StatsCalculator
    def self.calculate
      {
        total_jobs: SolidQueue::Job.count,
        ready_jobs: SolidQueue::ReadyExecution.count,
        scheduled_jobs: SolidQueue::ScheduledExecution.count,
        failed_jobs: SolidQueue::FailedExecution.count,
        in_progress_jobs: SolidQueue::Execution.count
      }
    end
  end
end

RSpec.describe 'SolidQueueMonitor::StatsCalculator' do
  describe '.calculate' do
    it 'returns statistics about solid queue jobs' do
      stats = SolidQueueMonitor::StatsCalculator.calculate

      expect(stats[:total_jobs]).to eq(10)
      expect(stats[:ready_jobs]).to eq(5)
      expect(stats[:scheduled_jobs]).to eq(2)
      expect(stats[:failed_jobs]).to eq(1)
      expect(stats[:in_progress_jobs]).to eq(2)
    end
  end
end
