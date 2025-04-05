# frozen_string_literal: true

module SolidQueueMonitor
  class ScheduledJobsPresenter < BasePresenter
    include Rails.application.routes.url_helpers
    include SolidQueueMonitor::Engine.routes.url_helpers

    def initialize(jobs, current_page: 1, total_pages: 1, filters: {})
      @jobs = jobs
      @current_page = current_page
      @total_pages = total_pages
      @filters = filters
    end

    def render
      section_wrapper('Scheduled Jobs', generate_filter_form + generate_table_with_actions)
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
              <a href="#{scheduled_jobs_path}" class="reset-button">Reset</a>
            </div>
          </form>
        </div>

        <div class="bulk-actions-bar">
          <button type="button" class="action-button execute-button" id="execute-selected-top" disabled>Execute Selected</button>
        </div>
      HTML
    end

    def generate_table_with_actions
      <<-HTML
      <form id="scheduled-jobs-form" action="#{execute_jobs_path}" method="POST">
        #{generate_table}
      </form>
      <script>
        document.addEventListener('DOMContentLoaded', function() {
          const selectAllCheckbox = document.querySelector('th input[type="checkbox"]');
          const jobCheckboxes = document.getElementsByName('job_ids[]');
          const executeButton = document.getElementById('execute-selected-top');
          const form = document.getElementById('scheduled-jobs-form');
      #{'    '}
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
      #{'    '}
          // Add event listener for the execute button
          executeButton.addEventListener('click', function() {
            const selectedIds = Array.from(document.querySelectorAll('input[name="job_ids[]"]:checked')).map(cb => cb.value);
            if (selectedIds.length === 0) return;
      #{'      '}
            // Add selected IDs as hidden inputs
            selectedIds.forEach(id => {
              const input = document.createElement('input');
              input.type = 'hidden';
              input.name = 'job_ids[]';
              input.value = id;
              form.appendChild(input);
            });
      #{'      '}
            form.submit();
          });
      #{'    '}
          function updateExecuteButton() {
            const checkboxes = document.getElementsByName('job_ids[]');
            const checked = Array.from(checkboxes).some(cb => cb.checked);
            executeButton.disabled = !checked;
          }
      #{'    '}
          // Initialize button state
          updateExecuteButton();
        });
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
              #{@jobs.map { |execution| generate_row(execution) }.join}
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
