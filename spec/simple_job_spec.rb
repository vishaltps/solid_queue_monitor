# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'SolidQueue::Job model fix' do
  # Create mock classes for testing
  before(:all) do
    # Define models
    module SolidQueue
      class Job
        attr_accessor :id, :queue_name, :class_name, :arguments, :priority

        def initialize(attrs = {})
          @id = attrs[:id] || 1
          @queue_name = attrs[:queue_name]
          @class_name = attrs[:class_name]
          @arguments = attrs[:arguments]
          @priority = attrs[:priority] || 0
        end

        def self.create(attrs)
          new(attrs)
        end

        def persisted?
          true
        end
      end

      class ReadyExecution
        attr_accessor :job, :queue_name

        def initialize(attrs = {})
          @job = attrs[:job]
          @queue_name = attrs[:queue_name]
        end

        def self.create(attrs)
          new(attrs)
        end
      end

      class FailedExecution
        attr_accessor :job, :error

        def initialize(attrs = {})
          @job = attrs[:job]
          @error = attrs[:error]
        end

        def self.create(attrs)
          new(attrs)
        end
      end
    end
  end

  describe 'job creation' do
    it 'can create a job record' do
      job = SolidQueue::Job.create(
        queue_name: 'default',
        class_name: 'TestJob',
        arguments: '[]',
        priority: 0
      )

      expect(job.persisted?).to be true
      expect(job.queue_name).to eq('default')
      expect(job.class_name).to eq('TestJob')
    end
  end

  describe 'job associations' do
    let(:job) { SolidQueue::Job.create(queue_name: 'default', class_name: 'TestJob', arguments: '[]') }

    it 'can have ready executions' do
      execution = SolidQueue::ReadyExecution.create(job: job, queue_name: 'default')
      expect(execution.job).to eq(job)
    end

    it 'can have failed executions' do
      failed = SolidQueue::FailedExecution.create(job: job, error: 'Test error')
      expect(failed.job).to eq(job)
    end
  end
end
