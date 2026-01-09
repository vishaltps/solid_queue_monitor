# frozen_string_literal: true

module SolidQueueMonitor
  class QueuesController < BaseController
    def index
      @queues = SolidQueue::Job.group(:queue_name)
                               .select('queue_name, COUNT(*) as job_count')
                               .order('job_count DESC')
      @paused_queues = QueuePauseService.paused_queues

      render_page('Queues', SolidQueueMonitor::QueuesPresenter.new(@queues, @paused_queues).render)
    end

    def pause
      queue_name = params[:queue_name]
      result = QueuePauseService.new(queue_name).pause

      set_flash_message(result[:message], result[:success] ? 'success' : 'error')
      redirect_to queues_path
    end

    def resume
      queue_name = params[:queue_name]
      result = QueuePauseService.new(queue_name).resume

      set_flash_message(result[:message], result[:success] ? 'success' : 'error')
      redirect_to queues_path
    end
  end
end
