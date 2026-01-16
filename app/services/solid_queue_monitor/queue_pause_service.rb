# frozen_string_literal: true

module SolidQueueMonitor
  class QueuePauseService
    delegate :paused?, to: :@queue

    def initialize(queue_name)
      @queue_name = queue_name
      @queue = SolidQueue::Queue.new(queue_name)
    end

    def pause
      return { success: false, message: "Queue '#{@queue_name}' is already paused" } if paused?

      @queue.pause
      { success: true, message: "Queue '#{@queue_name}' has been paused" }
    rescue StandardError => e
      { success: false, message: "Failed to pause queue: #{e.message}" }
    end

    def resume
      return { success: false, message: "Queue '#{@queue_name}' is not paused" } unless paused?

      @queue.resume
      { success: true, message: "Queue '#{@queue_name}' has been resumed" }
    rescue StandardError => e
      { success: false, message: "Failed to resume queue: #{e.message}" }
    end

    def self.paused_queues
      SolidQueue::Pause.pluck(:queue_name)
    end
  end
end
