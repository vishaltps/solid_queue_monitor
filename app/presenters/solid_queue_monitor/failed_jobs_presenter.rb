# frozen_string_literal: true

module SolidQueueMonitor
  class FailedJobsPresenter < BasePresenter
    include Rails.application.routes.url_helpers
    include SolidQueueMonitor::Engine.routes.url_helpers

    def initialize(jobs, current_page: 1, total_pages: 1, filters: {})
      @jobs = jobs
      @current_page = current_page
      @total_pages = total_pages
      @filters = filters
    end

    def render
      section_wrapper('Failed Jobs',
                      generate_filter_form + generate_table + generate_pagination(@current_page, @total_pages))
    end

    private

    def generate_filter_form
      <<-HTML
        <div class="filter-form-container">
          <form method="get" action="#{failed_jobs_path}" class="filter-form">
            <div class="filter-group">
              <label for="class_name">Job Class:</label>
              <input type="text" name="class_name" id="class_name" value="#{@filters[:class_name]}" placeholder="Filter by class name">
            </div>

            <div class="filter-group">
              <label for="queue_name">Queue:</label>
              <input type="text" name="queue_name" id="queue_name" value="#{@filters[:queue_name]}" placeholder="Filter by queue">
            </div>

            <div class="filter-group">
              <label for="arguments">Arguments:</label>
              <input type="text" name="arguments" id="arguments" value="#{@filters[:arguments]}" placeholder="Filter by arguments">
            </div>

            <div class="filter-actions">
              <button type="submit" class="filter-button">Apply Filters</button>
              <a href="#{failed_jobs_path}" class="reset-button">Reset</a>
            </div>
          </form>
        </div>

        <div class="bulk-actions-bar">
          <button type="button" class="action-button retry-button" id="retry-selected-top" disabled>Retry Selected</button>
          <button type="button" class="action-button discard-button" id="discard-selected-top" disabled>Discard Selected</button>
        </div>
      HTML
    end

    def generate_table
      <<-HTML
        <form method="post" id="failed-jobs-form">
          <div class="table-container">
            <table>
              <thead>
                <tr>
                  <th><input type="checkbox" id="select-all" class="select-all-checkbox"></th>
                  <th>Job</th>
                  <th>Queue</th>
                  <th>Error</th>
                  <th>Arguments</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                #{@jobs.map { |failed_execution| generate_row(failed_execution) }.join}
              </tbody>
            </table>
          </div>
        </form>

        <script>
          document.addEventListener('DOMContentLoaded', function() {
            // Handle select all checkboxes
            const selectAllHeader = document.getElementById('select-all');
            const checkboxes = document.querySelectorAll('.job-checkbox');
            const retrySelectedBtn = document.getElementById('retry-selected-top');
            const discardSelectedBtn = document.getElementById('discard-selected-top');
            const form = document.getElementById('failed-jobs-form');
        #{'    '}
            function updateButtonState() {
              const checkedBoxes = document.querySelectorAll('.job-checkbox:checked');
              retrySelectedBtn.disabled = checkedBoxes.length === 0;
              discardSelectedBtn.disabled = checkedBoxes.length === 0;
            }
        #{'    '}
            function toggleAll(checked) {
              checkboxes.forEach(checkbox => {
                checkbox.checked = checked;
              });
              selectAllHeader.checked = checked;
              updateButtonState();
            }
        #{'    '}
            selectAllHeader.addEventListener('change', function() {
              toggleAll(this.checked);
            });
        #{'    '}
            checkboxes.forEach(checkbox => {
              checkbox.addEventListener('change', function() {
                updateButtonState();
        #{'        '}
                // Update select all checkboxes if needed
                const allChecked = document.querySelectorAll('.job-checkbox:checked').length === checkboxes.length;
                selectAllHeader.checked = allChecked;
              });
            });
        #{'    '}
            // Handle bulk actions
            retrySelectedBtn.addEventListener('click', function() {
              const selectedIds = Array.from(document.querySelectorAll('.job-checkbox:checked')).map(cb => cb.value);
              if (selectedIds.length === 0) return;
        #{'      '}
              if (confirm('Are you sure you want to retry the selected jobs?')) {
                form.action = '#{retry_failed_jobs_path}';
        #{'        '}
                // Add a special flag to indicate this should redirect properly
                const redirectInput = document.createElement('input');
                redirectInput.type = 'hidden';
                redirectInput.name = 'redirect_cleanly';
                redirectInput.value = 'true';
                form.appendChild(redirectInput);
        #{'        '}
                // Add selected IDs as hidden inputs
                selectedIds.forEach(id => {
                  const input = document.createElement('input');
                  input.type = 'hidden';
                  input.name = 'job_ids[]';
                  input.value = id;
                  form.appendChild(input);
                });
        #{'        '}
                // Submit the form and then replace the URL location immediately after
                form.submit();
        #{'        '}
                // Delay the redirect to give the form time to submit
                setTimeout(function() {
                  // Reset to the clean URL without query parameters
                  window.history.replaceState({}, '', window.location.pathname);
                }, 100);
              }
            });
        #{'    '}
            discardSelectedBtn.addEventListener('click', function() {
              const selectedIds = Array.from(document.querySelectorAll('.job-checkbox:checked')).map(cb => cb.value);
              if (selectedIds.length === 0) return;
        #{'      '}
              if (confirm('Are you sure you want to discard the selected jobs?')) {
                form.action = '#{discard_failed_jobs_path}';
        #{'        '}
                // Add a special flag to indicate this should redirect properly
                const redirectInput = document.createElement('input');
                redirectInput.type = 'hidden';
                redirectInput.name = 'redirect_cleanly';
                redirectInput.value = 'true';
                form.appendChild(redirectInput);
        #{'        '}
                // Add selected IDs as hidden inputs
                selectedIds.forEach(id => {
                  const input = document.createElement('input');
                  input.type = 'hidden';
                  input.name = 'job_ids[]';
                  input.value = id;
                  form.appendChild(input);
                });
        #{'        '}
                // Submit the form and then replace the URL location immediately after
                form.submit();
        #{'        '}
                // Delay the redirect to give the form time to submit
                setTimeout(function() {
                  // Reset to the clean URL without query parameters
                  window.history.replaceState({}, '', window.location.pathname);
                }, 100);
              }
            });
        #{'    '}
            // Initialize button state
            updateButtonState();
        #{'    '}
            // Global function for retry action
            window.submitRetryForm = function(id) {
              const form = document.createElement('form');
              form.method = 'post';
              form.action = '#{retry_failed_job_path(id: 'PLACEHOLDER')}';
              form.action = form.action.replace('PLACEHOLDER', id);
              form.style.display = 'none';
        #{'      '}
              // Add a special flag to indicate this should redirect properly
              const redirectInput = document.createElement('input');
              redirectInput.type = 'hidden';
              redirectInput.name = 'redirect_cleanly';
              redirectInput.value = 'true';
              form.appendChild(redirectInput);
        #{'      '}
              document.body.appendChild(form);
        #{'      '}
              // Submit the form and then replace the URL location immediately after
              form.submit();
        #{'      '}
              // Delay the redirect to give the form time to submit
              setTimeout(function() {
                // Reset to the clean URL without query parameters
                window.history.replaceState({}, '', window.location.pathname);
              }, 100);
            };
        #{'    '}
            // Global function for discard action
            window.submitDiscardForm = function(id) {
              if (confirm('Are you sure you want to discard this job?')) {
                const form = document.createElement('form');
                form.method = 'post';
                form.action = '#{discard_failed_job_path(id: 'PLACEHOLDER')}';
                form.action = form.action.replace('PLACEHOLDER', id);
                form.style.display = 'none';
        #{'        '}
                // Add a special flag to indicate this should redirect properly
                const redirectInput = document.createElement('input');
                redirectInput.type = 'hidden';
                redirectInput.name = 'redirect_cleanly';
                redirectInput.value = 'true';
                form.appendChild(redirectInput);
        #{'        '}
                document.body.appendChild(form);
        #{'        '}
                // Submit the form and then replace the URL location immediately after
                form.submit();
        #{'        '}
                // Delay the redirect to give the form time to submit
                setTimeout(function() {
                  // Reset to the clean URL without query parameters
                  window.history.replaceState({}, '', window.location.pathname);
                }, 100);
              }
            };
          });
        </script>
      HTML
    end

    def generate_row(failed_execution)
      job = failed_execution.job
      error = parse_error(failed_execution.error)

      <<-HTML
        <tr>
          <td><input type="checkbox" class="job-checkbox" value="#{failed_execution.id}"></td>
          <td>
            <div class="job-class">#{job.class_name}</div>
            <div class="job-meta">
              <span class="job-timestamp">Queued at: #{format_datetime(job.created_at)}</span>
            </div>
          </td>
          <td>
            <div class="job-queue">#{job.queue_name}</div>
          </td>
          <td>
            <div class="error-message">#{error[:message]}</div>
            <div class="job-meta">
              <span class="job-timestamp">Failed at: #{format_datetime(failed_execution.created_at)}</span>
            </div>
            <details>
              <summary>Backtrace</summary>
              <pre class="error-backtrace">#{error[:backtrace]}</pre>
            </details>
          </td>
          <td>#{format_arguments(job.arguments)}</td>
          <td class="actions-cell">
            <div class="job-actions">
              <a href="javascript:void(0)"#{' '}
                 onclick="submitRetryForm(#{failed_execution.id})"#{' '}
                 class="action-button retry-button">Retry</a>
        #{'      '}
              <a href="javascript:void(0)"#{' '}
                 onclick="submitDiscardForm(#{failed_execution.id})"#{' '}
                 class="action-button discard-button">Discard</a>
            </div>
          </td>
        </tr>
      HTML
    end

    def parse_error(error)
      return { message: 'Unknown error', backtrace: '' } unless error

      if error.is_a?(String)
        { message: error, backtrace: '' }
      elsif error.is_a?(Hash)
        message = error['message'] || error[:message] || 'Unknown error'
        backtrace = error['backtrace'] || error[:backtrace] || []
        backtrace = backtrace.join("\n") if backtrace.is_a?(Array)
        { message: message, backtrace: backtrace }
      else
        { message: 'Unknown error format', backtrace: error.to_s }
      end
    end

    def get_queue_name(failed_execution, job)
      # Try to get queue_name from failed_execution if the method exists
      if failed_execution.respond_to?(:queue_name) && !failed_execution.queue_name.nil?
        failed_execution.queue_name
      else
        # Fall back to job's queue_name
        job.queue_name
      end
    rescue NoMethodError
      # If there's an error accessing queue_name, fall back to job's queue_name
      job.queue_name
    end
  end
end
