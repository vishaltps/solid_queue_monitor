# frozen_string_literal: true

module SolidQueueMonitor
  class FailedJobsPresenter < BasePresenter
    include Rails.application.routes.url_helpers
    include SolidQueueMonitor::Engine.routes.url_helpers

    def initialize(jobs, current_page: 1, total_pages: 1, filters: {}, sort: {}, nonce: nil)
      @jobs = jobs
      @current_page = current_page
      @total_pages = total_pages
      @filters = filters
      @sort = sort
      @nonce = nonce
    end

    def render
      section_wrapper('Failed Jobs',
                      generate_filter_form + generate_table + generate_pagination(@current_page, @total_pages))
    end

    private

    def script_tag_open
      @nonce ? %(<script nonce="#{@nonce}">) : '<script>'
    end

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
                  #{sortable_header('class_name', 'Job')}
                  #{sortable_header('queue_name', 'Queue')}
                  <th>Error</th>
                  <th>Arguments</th>
                  #{sortable_header('created_at', 'Failed At')}
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                #{@jobs.map { |failed_execution| generate_row(failed_execution) }.join}
              </tbody>
            </table>
          </div>
        </form>

        #{script_tag_open}
          document.addEventListener('DOMContentLoaded', function() {
            var selectAllHeader = document.getElementById('select-all');
            var checkboxes = document.querySelectorAll('.job-checkbox');
            var retrySelectedBtn = document.getElementById('retry-selected-top');
            var discardSelectedBtn = document.getElementById('discard-selected-top');
            var form = document.getElementById('failed-jobs-form');

            function updateButtonState() {
              var checkedBoxes = document.querySelectorAll('.job-checkbox:checked');
              retrySelectedBtn.disabled = checkedBoxes.length === 0;
              discardSelectedBtn.disabled = checkedBoxes.length === 0;
            }

            selectAllHeader.addEventListener('change', function() {
              checkboxes.forEach(function(cb) { cb.checked = selectAllHeader.checked; });
              updateButtonState();
            });

            checkboxes.forEach(function(cb) {
              cb.addEventListener('change', function() {
                updateButtonState();
                var allChecked = document.querySelectorAll('.job-checkbox:checked').length === checkboxes.length;
                selectAllHeader.checked = allChecked;
              });
            });

            function bulkSubmit(action, promptMsg) {
              var ids = Array.from(document.querySelectorAll('.job-checkbox:checked')).map(function(cb) { return cb.value; });
              if (ids.length === 0) return;
              if (!confirm(promptMsg)) return;
              form.action = action;
              appendHidden(form, 'redirect_cleanly', 'true');
              ids.forEach(function(id) { appendHidden(form, 'job_ids[]', id); });
              form.submit();
              setTimeout(function() { window.history.replaceState({}, '', window.location.pathname); }, 100);
            }

            function appendHidden(f, name, value) {
              var input = document.createElement('input');
              input.type = 'hidden';
              input.name = name;
              input.value = value;
              f.appendChild(input);
            }

            retrySelectedBtn.addEventListener('click', function() {
              bulkSubmit('#{retry_failed_jobs_path}', 'Are you sure you want to retry the selected jobs?');
            });
            discardSelectedBtn.addEventListener('click', function() {
              bulkSubmit('#{discard_failed_jobs_path}', 'Are you sure you want to discard the selected jobs?');
            });

            function submitRowAction(action, id) {
              var f = document.createElement('form');
              f.method = 'post';
              f.action = action.replace('PLACEHOLDER', id);
              appendHidden(f, 'redirect_cleanly', 'true');
              document.body.appendChild(f);
              f.submit();
              setTimeout(function() { window.history.replaceState({}, '', window.location.pathname); }, 100);
            }

            document.addEventListener('click', function(e) {
              var btn = e.target.closest('[data-action]');
              if (!btn) return;
              var id = btn.dataset.jobId;
              if (btn.dataset.action === 'retry-failed-job') {
                submitRowAction('#{retry_failed_job_path(id: 'PLACEHOLDER')}', id);
              } else if (btn.dataset.action === 'discard-failed-job') {
                if (confirm('Are you sure you want to discard this job?')) {
                  submitRowAction('#{discard_failed_job_path(id: 'PLACEHOLDER')}', id);
                }
              }
            });

            updateButtonState();
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
            <div class="job-class"><a href="#{job_path(job)}" class="job-class-link">#{job.class_name}</a></div>
            <div class="job-meta">
              <span class="job-timestamp">Queued at: #{format_datetime(job.created_at)}</span>
            </div>
          </td>
          <td>
            <div class="job-queue">#{queue_link(job.queue_name)}</div>
          </td>
          <td>
            <div class="error-message">#{error[:message].to_s.truncate(100)}</div>
          </td>
          <td>#{format_arguments(job.arguments)}</td>
          <td>#{format_datetime(failed_execution.created_at)}</td>
          <td class="actions-cell">
            <div class="job-actions">
              <button type="button" data-action="retry-failed-job" data-job-id="#{failed_execution.id}" class="action-button retry-button">Retry</button>
              <button type="button" data-action="discard-failed-job" data-job-id="#{failed_execution.id}" class="action-button discard-button">Discard</button>
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
