module SolidQueueMonitor
  class JobsPresenter < BasePresenter
    def initialize(jobs, current_page: 1, total_pages: 1)
      @jobs = jobs
      @current_page = current_page
      @total_pages = total_pages
    end

    def render
      section_wrapper('Recent Jobs', generate_table + generate_pagination(@current_page, @total_pages))
    end

    private

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
              <tbody>
              #{@jobs.map { |job| generate_row(job) }.join}
            </tbody>
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