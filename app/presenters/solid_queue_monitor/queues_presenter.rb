# frozen_string_literal: true

module SolidQueueMonitor
  class QueuesPresenter < BasePresenter
    def initialize(records, paused_queues = [])
      @records = records
      @paused_queues = paused_queues
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
                <th>Status</th>
                <th>Total Jobs</th>
                <th>Ready Jobs</th>
                <th>Scheduled Jobs</th>
                <th>Failed Jobs</th>
                <th>Actions</th>
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
      queue_name = queue.queue_name || 'default'
      paused = @paused_queues.include?(queue_name)

      <<-HTML
        <tr class="#{paused ? 'queue-paused' : ''}">
          <td>#{queue_link(queue_name)}</td>
          <td>#{status_badge(paused)}</td>
          <td>#{queue.job_count}</td>
          <td>#{ready_jobs_count(queue_name)}</td>
          <td>#{scheduled_jobs_count(queue_name)}</td>
          <td>#{failed_jobs_count(queue_name)}</td>
          <td class="actions-cell">#{action_button(queue_name, paused)}</td>
        </tr>
      HTML
    end

    def status_badge(paused)
      if paused
        '<span class="status-badge status-paused">Paused</span>'
      else
        '<span class="status-badge status-active">Active</span>'
      end
    end

    def action_button(queue_name, paused)
      if paused
        <<-HTML
          <form action="#{resume_queue_path}" method="post" class="inline-form">
            <input type="hidden" name="queue_name" value="#{queue_name}">
            <button type="submit" class="action-button resume-button" title="Resume queue processing">
              Resume
            </button>
          </form>
        HTML
      else
        <<-HTML
          <form action="#{pause_queue_path}" method="post" class="inline-form"
                onsubmit="return confirm('Are you sure you want to pause the #{queue_name} queue? Workers will stop processing jobs from this queue.');">
            <input type="hidden" name="queue_name" value="#{queue_name}">
            <button type="submit" class="action-button pause-button" title="Pause queue processing">
              Pause
            </button>
          </form>
        HTML
      end
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
