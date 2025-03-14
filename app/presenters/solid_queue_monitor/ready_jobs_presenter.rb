module SolidQueueMonitor
  class ReadyJobsPresenter < BasePresenter
    def initialize(records, current_page: 1, total_pages: 1)
      @records = records
      @current_page = current_page
      @total_pages = total_pages
    end


    def render
      section_wrapper('Ready Jobs', generate_table + generate_pagination(@current_page, @total_pages))
    end

    private

    def generate_table
      <<-HTML
        <div class="table-container">
          <table>
            <thead>
              <tr>
                <th>Job</th>
                <th>Queue</th>
                <th>Priority</th>
                <th>Arguments</th>
                <th>Created At</th>
              </tr>
            </thead>
            <tbody>
              #{@records.map { |execution| generate_row(execution) }.join}
            </tbody>
          </table>
        </div>
      HTML
    end

    def generate_row(execution)
      <<-HTML
        <tr>
          <td>#{execution.job.class_name}</td>
          <td>#{execution.queue_name}</td>
          <td>#{execution.priority}</td>
          <td>#{format_arguments(execution.job.arguments)}</td>
          <td>#{format_datetime(execution.created_at)}</td>
        </tr>
      HTML
    end
  end
end