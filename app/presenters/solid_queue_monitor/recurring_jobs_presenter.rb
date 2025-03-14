module SolidQueueMonitor
  class RecurringJobsPresenter < BasePresenter
    def initialize(records, current_page: 1, total_pages: 1)
      @records = records
      @current_page = current_page
      @total_pages = total_pages
    end

    def render
      section_wrapper('Recurring Jobs', generate_table)
    end

    private

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
                <th>Last Run</th>
              </tr>
            </thead>
            <tbody>
              #{@records.map { |task| generate_row(task) }.join}
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
          <td>#{task.queue_name}</td>
          <td>#{format_datetime(task.last_run_at)}</td>
        </tr>
      HTML
    end
  end
end