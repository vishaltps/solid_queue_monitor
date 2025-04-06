# frozen_string_literal: true

module SolidQueueMonitor
  class QueuesController < BaseController
    def index
      @queues = SolidQueue::Job.group(:queue_name)
                               .select('queue_name, COUNT(*) as job_count')
                               .order('job_count DESC')

      render_page('Queues', SolidQueueMonitor::QueuesPresenter.new(@queues).render)
    end
  end
end
