# frozen_string_literal: true

require 'spec_helper'

# Use a different namespace to avoid conflicts
module MockSolidQueue
  class Job
    attr_accessor :id, :queue_name, :class_name, :arguments, :scheduled_at, :finished_at

    @@jobs = []
    @@id_counter = 1

    def initialize(attributes = {})
      @id = @@id_counter
      @@id_counter += 1

      attributes.each do |key, value|
        send("#{key}=", value) if respond_to?("#{key}=")
      end

      @created_at = Time.now
      @updated_at = Time.now
    end

    def save
      @@jobs << self
      true
    end

    def persisted?
      @@jobs.include?(self)
    end

    def self.create(attributes = {})
      job = new(attributes)
      job.save
      job
    end

    def self.all
      @@jobs
    end

    def self.find(id)
      @@jobs.find { |job| job.id == id }
    end

    def self.where(conditions = {})
      result = @@jobs

      conditions.each do |key, value|
        if value.is_a?(String) && value.include?('%')
          pattern = Regexp.new(value.gsub('%', '.*'))
          result = result.select { |job| job.send(key) =~ pattern }
        else
          result = result.select { |job| job.send(key) == value }
        end
      end

      result
    end

    def self.count
      @@jobs.size
    end

    def self.clear
      @@jobs = []
      @@id_counter = 1
    end
  end
end

RSpec.describe 'MockSolidQueue::Job model' do
  before do
    MockSolidQueue::Job.clear
  end

  describe '.create' do
    it 'creates a new job record' do
      job = MockSolidQueue::Job.create(queue_name: 'default', class_name: 'TestJob')

      expect(job.persisted?).to be true
      expect(job.queue_name).to eq('default')
      expect(job.class_name).to eq('TestJob')
    end
  end

  describe '.where' do
    before do
      MockSolidQueue::Job.create(queue_name: 'default', class_name: 'TestJob')
      MockSolidQueue::Job.create(queue_name: 'mailers', class_name: 'MailerJob')
      MockSolidQueue::Job.create(queue_name: 'default', class_name: 'AnotherJob')
    end

    it 'filters jobs by exact conditions' do
      jobs = MockSolidQueue::Job.where(queue_name: 'default')
      expect(jobs.length).to eq(2)
      expect(jobs.all? { |job| job.queue_name == 'default' }).to be true
    end

    it 'filters jobs by pattern conditions' do
      jobs = MockSolidQueue::Job.where(class_name: '%Job')
      expect(jobs.length).to eq(3)
    end

    it 'combines multiple conditions' do
      jobs = MockSolidQueue::Job.where(queue_name: 'default', class_name: 'TestJob')
      expect(jobs.length).to eq(1)
      expect(jobs.first.class_name).to eq('TestJob')
    end
  end

  describe '.count' do
    before do
      MockSolidQueue::Job.clear  # Make sure we start with a clean slate
      MockSolidQueue::Job.create(queue_name: 'default', class_name: 'TestJob')
      MockSolidQueue::Job.create(queue_name: 'mailers', class_name: 'MailerJob')
    end

    it 'returns the total number of jobs' do
      expect(MockSolidQueue::Job.count).to eq(2)
    end
  end
end
