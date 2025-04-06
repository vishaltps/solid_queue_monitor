# frozen_string_literal: true

module SolidQueueMonitor
  class QueuesPresenter < BasePresenter
    def initialize(records)
      @records = records
    end

    def render
      section_wrapper('Queues', generate_table)
    end

    private

    def generate_table
      <<-HTML
        <div class="table-container">
          <table>
            <thead>
              <tr>
                <th>Queue Name</th>
                <th>Total Jobs</th>
                <th>Ready Jobs</th>
                <th>Scheduled Jobs</th>
                <th>Failed Jobs</th>
              </tr>
            </thead>
            <tbody>
              #{@records.map { |queue| generate_row(queue) }.join}
            </tbody>
          </table>
        </div>
      HTML
    end

    def generate_row(queue)
      <<-HTML
        <tr>
          <td>#{queue.queue_name || 'default'}</td>
          <td>#{queue.job_count}</td>
          <td>#{ready_jobs_count(queue.queue_name)}</td>
          <td>#{scheduled_jobs_count(queue.queue_name)}</td>
          <td>#{failed_jobs_count(queue.queue_name)}</td>
        </tr>
      HTML
    end

    def ready_jobs_count(queue_name)
      SolidQueue::ReadyExecution.where(queue_name: queue_name).count
    end

    def scheduled_jobs_count(queue_name)
      SolidQueue::ScheduledExecution.where(queue_name: queue_name).count
    end

    def failed_jobs_count(queue_name)
      SolidQueue::FailedExecution.joins(:job)
                                 .where(solid_queue_jobs: { queue_name: queue_name })
                                 .count
    end
  end
end
