module SolidQueueMonitor
  class ScheduledJobsPresenter < BasePresenter

    include Rails.application.routes.url_helpers
    include SolidQueueMonitor::Engine.routes.url_helpers

    def initialize(records, current_page: 1, total_pages: 1)
      @records = records
      @current_page = current_page
      @total_pages = total_pages
    end

    def render
      section_wrapper('Scheduled Jobs', generate_form)
    end

    private

    def generate_form
      <<-HTML
      <form action="#{execute_jobs_path}" method="POST">
        #{generate_table}
        <div class="table-actions">
          <button type="submit" class="execute-btn" id="bulk-execute" disabled>Execute Selected</button>
        </div>
      </form>
      <script>
        document.addEventListener('DOMContentLoaded', function() {
          const selectAllCheckbox = document.querySelector('th input[type="checkbox"]');
          const jobCheckboxes = document.getElementsByName('job_ids[]');
          
          selectAllCheckbox.addEventListener('change', function() {
            jobCheckboxes.forEach(checkbox => checkbox.checked = this.checked);
            updateExecuteButton();
          });

          jobCheckboxes.forEach(checkbox => {
            checkbox.addEventListener('change', function() {
              selectAllCheckbox.checked = Array.from(jobCheckboxes).every(cb => cb.checked);
              updateExecuteButton();
            });
          });
        });

        function updateExecuteButton() {
          const checkboxes = document.getElementsByName('job_ids[]');
          const checked = Array.from(checkboxes).some(cb => cb.checked);
          document.getElementById('bulk-execute').disabled = !checked;
        }
      </script>
    HTML
    end

    def generate_table
      <<-HTML
        <div class="table-container">
          <table>
            <thead>
              <tr>
                <th width="50"><input type="checkbox"></th>
                <th>Job</th>
                <th>Queue</th>
                <th>Scheduled At</th>
                <th>Arguments</th>
              </tr>
            </thead>
            <tbody>
              #{@records.map { |execution| generate_row(execution) }.join}
            </tbody>
          </table>
        </div>
        #{generate_pagination(@current_page, @total_pages)}
      HTML
    end

    def generate_row(execution)
      <<-HTML
        <tr>
          <td>
            <input type="checkbox" name="job_ids[]" value="#{execution.id}" onchange="updateExecuteButton()">
          </td>
          <td>#{execution.job.class_name}</td>
          <td>#{execution.queue_name}</td>
          <td>#{format_datetime(execution.scheduled_at)}</td>
          <td>#{format_arguments(execution.job.arguments)}</td>
        </tr>
      HTML
    end
  end
end