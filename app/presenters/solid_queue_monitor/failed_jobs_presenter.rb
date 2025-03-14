module SolidQueueMonitor
  class FailedJobsPresenter < BasePresenter
    def initialize(jobs, current_page: 1, total_pages: 1, filters: {})
      @jobs = jobs
      @current_page = current_page
      @total_pages = total_pages
      @filters = filters
    end

    def render
      section_wrapper('Failed Jobs', generate_filter_form + generate_table + generate_pagination(@current_page, @total_pages))
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
              <a href="#{failed_jobs_path}" class="reset-button">Reset</a>
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
                <th>Error</th>
                <th>Failed At</th>
                <th>Arguments</th>
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
      <<-HTML
        <tr>
          <td>#{execution.job.class_name}</td>
          <td class="error-message">#{execution.error['message']}</td>
          <td>#{format_datetime(execution.created_at)}</td>
          <td>#{format_arguments(execution.job.arguments)}</td>
        </tr>
      HTML
    end
  end
end