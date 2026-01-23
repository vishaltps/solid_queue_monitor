# frozen_string_literal: true

module SolidQueueMonitor
  class InProgressJobsPresenter < BasePresenter
    include SolidQueueMonitor::Engine.routes.url_helpers

    def initialize(jobs, current_page: 1, total_pages: 1, filters: {})
      @jobs = jobs
      @current_page = current_page
      @total_pages = total_pages
      @filters = filters
    end

    def render
      section_wrapper('In Progress Jobs',
                      generate_filter_form + generate_table + generate_pagination(@current_page, @total_pages))
    end

    private

    def generate_filter_form
      <<-HTML
        <div class="filter-form-container">
          <form method="get" action="#{in_progress_jobs_path}" class="filter-form">
            <div class="filter-group">
              <label for="class_name">Job Class:</label>
              <input type="text" name="class_name" id="class_name" value="#{@filters[:class_name]}" placeholder="Filter by class name">
            </div>

            <div class="filter-group">
              <label for="arguments">Arguments:</label>
              <input type="text" name="arguments" id="arguments" value="#{@filters[:arguments]}" placeholder="Filter by arguments">
            </div>

            <div class="filter-actions">
              <button type="submit" class="filter-button">Apply Filters</button>
              <a href="#{in_progress_jobs_path}" class="reset-button">Reset</a>
            </div>
          </form>
        </div>
      HTML
    end

    def generate_table
      <<-HTML
        <div class="table-container">
          <table>
            <thead>
              <tr>
                <th>Job</th>
                <th>Queue</th>
                <th>Arguments</th>
                <th>Started At</th>
                <th>Process ID</th>
              </tr>
            </thead>
            <tbody>
              #{@jobs.map { |execution| generate_row(execution) }.join}
            </tbody>
          </table>
        </div>
      HTML
    end

    def generate_row(execution)
      job = execution.job
      <<-HTML
        <tr>
          <td>
            <div class="job-class"><a href="#{job_path(job)}" class="job-class-link">#{job.class_name}</a></div>
            <div class="job-meta">
              <span class="job-timestamp">Queued at: #{format_datetime(job.created_at)}</span>
            </div>
          </td>
          <td>#{queue_link(job.queue_name)}</td>
          <td>#{format_arguments(job.arguments)}</td>
          <td>#{format_datetime(execution.created_at)}</td>
          <td>#{execution.process_id}</td>
        </tr>
      HTML
    end
  end
end
