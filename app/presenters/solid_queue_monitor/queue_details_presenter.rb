# frozen_string_literal: true

module SolidQueueMonitor
  class QueueDetailsPresenter < BasePresenter
    def initialize(queue_name:, paused:, jobs:, counts:, current_page: 1, total_pages: 1, filters: {})
      @queue_name = queue_name
      @paused = paused
      @jobs = jobs
      @counts = counts
      @current_page = current_page
      @total_pages = total_pages
      @filters = filters
    end

    def render
      section_wrapper("Queue: #{@queue_name}",
                      render_header + render_stats_cards + generate_filter_form + generate_table + generate_pagination(@current_page, @total_pages))
    end

    private

    def render_header
      <<-HTML
        <div class="section-header-row">
          <div class="section-header-left">
            #{status_badge}
          </div>
          <div class="section-header-right">
            #{action_button}
          </div>
        </div>
      HTML
    end

    def status_badge
      if @paused
        '<span class="status-badge status-paused">Paused</span>'
      else
        '<span class="status-badge status-active">Active</span>'
      end
    end

    def action_button
      if @paused
        <<-HTML
          <form action="#{resume_queue_path}" method="post" class="inline-form">
            <input type="hidden" name="queue_name" value="#{@queue_name}">
            <input type="hidden" name="redirect_to" value="#{queue_details_path(queue_name: @queue_name)}">
            <button type="submit" class="action-button resume-button">Resume Queue</button>
          </form>
        HTML
      else
        <<-HTML
          <form action="#{pause_queue_path}" method="post" class="inline-form"
                onsubmit="return confirm('Are you sure you want to pause this queue?');">
            <input type="hidden" name="queue_name" value="#{@queue_name}">
            <input type="hidden" name="redirect_to" value="#{queue_details_path(queue_name: @queue_name)}">
            <button type="submit" class="action-button pause-button">Pause Queue</button>
          </form>
        HTML
      end
    end

    def render_stats_cards
      <<-HTML
        <div class="stats-container">
          <div class="stats">
            #{generate_stat_card('Total Jobs', @counts[:total])}
            #{generate_stat_card('Ready', @counts[:ready])}
            #{generate_stat_card('Scheduled', @counts[:scheduled])}
            #{generate_stat_card('In Progress', @counts[:in_progress])}
            #{generate_stat_card('Completed', @counts[:completed])}
            #{generate_stat_card('Failed', @counts[:failed])}
          </div>
        </div>
      HTML
    end

    def generate_stat_card(title, value)
      <<-HTML
        <div class="stat-card">
          <h3>#{title}</h3>
          <p>#{value}</p>
        </div>
      HTML
    end

    def generate_filter_form
      <<-HTML
        <div class="filter-form-container">
          <form method="get" action="#{queue_details_path(queue_name: @queue_name)}" class="filter-form">
            <div class="filter-group">
              <label for="class_name">Job Class:</label>
              <input type="text" name="class_name" id="class_name" value="#{@filters[:class_name]}" placeholder="Filter by class name">
            </div>

            <div class="filter-group">
              <label for="arguments">Arguments:</label>
              <input type="text" name="arguments" id="arguments" value="#{@filters[:arguments]}" placeholder="Filter by arguments">
            </div>

            <div class="filter-group">
              <label for="status">Status:</label>
              <select name="status" id="status">
                <option value="">All Statuses</option>
                <option value="completed" #{@filters[:status] == 'completed' ? 'selected' : ''}>Completed</option>
                <option value="failed" #{@filters[:status] == 'failed' ? 'selected' : ''}>Failed</option>
                <option value="scheduled" #{@filters[:status] == 'scheduled' ? 'selected' : ''}>Scheduled</option>
                <option value="pending" #{@filters[:status] == 'pending' ? 'selected' : ''}>Pending</option>
                <option value="in_progress" #{@filters[:status] == 'in_progress' ? 'selected' : ''}>In Progress</option>
              </select>
            </div>

            <div class="filter-actions">
              <button type="submit" class="filter-button">Apply Filters</button>
              <a href="#{queue_details_path(queue_name: @queue_name)}" class="reset-button">Reset</a>
            </div>
          </form>
        </div>
      HTML
    end

    def generate_table
      return '<p class="empty-message">No jobs in this queue</p>' if @jobs.empty?

      <<-HTML
        <div class="table-container">
          <table>
            <thead>
              <tr>
                <th>ID</th>
                <th>Job</th>
                <th>Arguments</th>
                <th>Status</th>
                <th>Created At</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              #{@jobs.map { |job| generate_row(job) }.join}
            </tbody>
          </table>
        </div>
      HTML
    end

    def generate_row(job)
      status = job_status(job)

      row_html = <<-HTML
        <tr>
          <td><a href="#{job_path(job)}" class="job-class-link">#{job.id}</a></td>
          <td><a href="#{job_path(job)}" class="job-class-link">#{job.class_name}</a></td>
          <td>#{format_arguments(job.arguments)}</td>
          <td><span class="status-badge status-#{status}">#{status}</span></td>
          <td>#{format_datetime(job.created_at)}</td>
      HTML

      # Add actions column for failed jobs
      if status == 'failed'
        failed_execution = SolidQueue::FailedExecution.find_by(job_id: job.id)

        row_html += if failed_execution
                      <<-HTML
          <td class="actions-cell">
            <div class="job-actions">
              <form method="post" action="#{retry_failed_job_path(id: failed_execution.id)}" class="inline-form">
                <input type="hidden" name="redirect_to" value="#{queue_details_path(queue_name: @queue_name)}">
                <button type="submit" class="action-button retry-button">Retry</button>
              </form>
              <form method="post" action="#{discard_failed_job_path(id: failed_execution.id)}" class="inline-form"
                    onsubmit="return confirm('Are you sure you want to discard this job?');">
                <input type="hidden" name="redirect_to" value="#{queue_details_path(queue_name: @queue_name)}">
                <button type="submit" class="action-button discard-button">Discard</button>
              </form>
            </div>
          </td>
                      HTML
                    else
                      '<td></td>'
                    end
      else
        row_html += '<td></td>'
      end

      row_html += '</tr>'
      row_html
    end

    def job_status(job)
      SolidQueueMonitor::StatusCalculator.new(job).calculate
    end
  end
end
