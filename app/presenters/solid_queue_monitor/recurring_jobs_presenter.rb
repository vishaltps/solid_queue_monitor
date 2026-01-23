# frozen_string_literal: true

module SolidQueueMonitor
  class RecurringJobsPresenter < BasePresenter
    include Rails.application.routes.url_helpers
    include SolidQueueMonitor::Engine.routes.url_helpers

    def initialize(jobs, current_page: 1, total_pages: 1, filters: {})
      @jobs = jobs
      @current_page = current_page
      @total_pages = total_pages
      @filters = filters
    end

    def render
      section_wrapper('Recurring Jobs',
                      generate_filter_form + generate_table + generate_pagination(@current_page, @total_pages))
    end

    private

    def generate_filter_form
      <<-HTML
        <div class="filter-form-container">
          <form method="get" action="" class="filter-form">
            <div class="filter-group">
              <label for="class_name">Job Class:</label>
              <input type="text" name="class_name" id="class_name" value="#{@filters[:class_name]}" placeholder="Filter by class name">
            </div>

            <div class="filter-group">
              <label for="queue_name">Queue:</label>
              <input type="text" name="queue_name" id="queue_name" value="#{@filters[:queue_name]}" placeholder="Filter by queue">
            </div>

            <div class="filter-actions">
              <button type="submit" class="filter-button">Apply Filters</button>
              <a href="#{recurring_jobs_path}" class="reset-button">Reset</a>
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
                <th>Key</th>
                <th>Job</th>
                <th>Schedule</th>
                <th>Queue</th>
                <th>Priority</th>
                <th>Last Updated</th>
              </tr>
            </thead>
            <tbody>
              #{@jobs.map { |task| generate_row(task) }.join}
            </tbody>
          </table>
        </div>
      HTML
    end

    def generate_row(task)
      <<-HTML
        <tr>
          <td>#{task.key}</td>
          <td>#{task.class_name}</td>
          <td>#{task.schedule}</td>
          <td>#{queue_link(task.queue_name)}</td>
          <td>#{task.priority || 'Default'}</td>
          <td>#{format_datetime(task.updated_at)}</td>
        </tr>
      HTML
    end
  end
end
