module SolidQueueMonitor
  class JobsPresenter < BasePresenter
    include Rails.application.routes.url_helpers
    include SolidQueueMonitor::Engine.routes.url_helpers

    def initialize(jobs, current_page: 1, total_pages: 1, filters: {})
      @jobs = jobs
      @current_page = current_page
      @total_pages = total_pages
      @filters = filters
    end

    def render
      <<-HTML
        <div class="section-wrapper">
          <div class="section">
            <h3>Recent Jobs</h3>
            #{generate_filter_form}
            #{generate_table}
            #{generate_pagination(@current_page, @total_pages)}
          </div>
        </div>
      HTML
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

            <div class="filter-group">
              <label for="status">Status:</label>
              <select name="status" id="status">
                <option value="">All Statuses</option>
                <option value="completed" #{@filters[:status] == 'completed' ? 'selected' : ''}>Completed</option>
                <option value="failed" #{@filters[:status] == 'failed' ? 'selected' : ''}>Failed</option>
                <option value="scheduled" #{@filters[:status] == 'scheduled' ? 'selected' : ''}>Scheduled</option>
                <option value="pending" #{@filters[:status] == 'pending' ? 'selected' : ''}>Pending</option>
              </select>
            </div>

            <div class="filter-actions">
              <button type="submit" class="filter-button">Apply Filters</button>
              <a href="#{root_path}" class="reset-button">Reset</a>
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
                <th>ID</th>
                <th>Job</th>
                <th>Queue</th>
                <th>Status</th>
                <th>Created At</th>
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
      <<-HTML
        <tr>
          <td>#{job.id}</td>
          <td>#{job.class_name}</td>
          <td>#{job.queue_name}</td>
          <td><span class='status-badge status-#{status}'>#{status}</span></td>
          <td>#{format_datetime(job.created_at)}</td>
        </tr>
      HTML
    end

    def job_status(job)
      SolidQueueMonitor::StatusCalculator.new(job).calculate
    end
  end
end