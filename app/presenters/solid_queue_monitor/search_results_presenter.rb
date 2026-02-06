# frozen_string_literal: true

module SolidQueueMonitor
  class SearchResultsPresenter < BasePresenter
    def initialize(query, results)
      @query = query
      @results = results
    end

    def render
      section_wrapper('Search Results', generate_content)
    end

    private

    def generate_content
      if @query.blank?
        generate_empty_query_message
      elsif total_count.zero?
        generate_no_results_message
      else
        generate_results_summary + generate_all_sections
      end
    end

    def generate_empty_query_message
      <<-HTML
        <div class="empty-state">
          <p>Enter a search term in the header to find jobs across all categories.</p>
        </div>
      HTML
    end

    def generate_no_results_message
      <<-HTML
        <div class="empty-state">
          <p>No results found for "#{escape_html(@query)}"</p>
          <p class="results-summary">0 results</p>
        </div>
      HTML
    end

    def generate_results_summary
      <<-HTML
        <div class="results-summary">
          <p>Found #{total_count} #{total_count == 1 ? 'result' : 'results'} for "#{escape_html(@query)}"</p>
        </div>
      HTML
    end

    def generate_all_sections
      sections = []
      sections << generate_ready_section if @results[:ready].any?
      sections << generate_scheduled_section if @results[:scheduled].any?
      sections << generate_failed_section if @results[:failed].any?
      sections << generate_in_progress_section if @results[:in_progress].any?
      sections << generate_completed_section if @results[:completed].any?
      sections << generate_recurring_section if @results[:recurring].any?
      sections.join
    end

    def generate_ready_section
      generate_section('Ready Jobs', @results[:ready]) do |execution|
        generate_job_row(execution.job, execution.queue_name, execution.created_at)
      end
    end

    def generate_scheduled_section
      generate_section('Scheduled Jobs', @results[:scheduled]) do |execution|
        generate_job_row(execution.job, execution.queue_name, execution.scheduled_at, 'Scheduled for')
      end
    end

    def generate_failed_section
      generate_section('Failed Jobs', @results[:failed]) do |execution|
        generate_failed_row(execution)
      end
    end

    def generate_in_progress_section
      generate_section('In Progress Jobs', @results[:in_progress]) do |execution|
        generate_job_row(execution.job, execution.job.queue_name, execution.created_at, 'Started at')
      end
    end

    def generate_completed_section
      generate_section('Completed Jobs', @results[:completed]) do |job|
        generate_completed_row(job)
      end
    end

    def generate_recurring_section
      generate_section('Recurring Tasks', @results[:recurring]) do |task|
        generate_recurring_row(task)
      end
    end

    def generate_section(title, items)
      <<-HTML
        <div class="search-results-section">
          <h3>#{title} (#{items.size})</h3>
          <div class="table-container">
            <table>
              <thead>
                <tr>
                  #{section_headers(title)}
                </tr>
              </thead>
              <tbody>
                #{items.map { |item| yield(item) }.join}
              </tbody>
            </table>
          </div>
        </div>
      HTML
    end

    def section_headers(title)
      case title
      when 'Recurring Tasks'
        '<th>Key</th><th>Class</th><th>Schedule</th><th>Queue</th>'
      when 'Failed Jobs'
        '<th>Job</th><th>Queue</th><th>Error</th><th>Failed At</th>'
      when 'Completed Jobs'
        '<th>Job</th><th>Queue</th><th>Arguments</th><th>Completed At</th>'
      else
        '<th>Job</th><th>Queue</th><th>Arguments</th><th>Time</th>'
      end
    end

    def generate_job_row(job, queue_name, time, time_label = 'Created at')
      <<-HTML
        <tr>
          <td><a href="#{job_path(job)}" class="job-class-link">#{job.class_name}</a></td>
          <td>#{queue_link(queue_name)}</td>
          <td>#{format_arguments(job.arguments)}</td>
          <td>
            <span class="job-timestamp">#{time_label}: #{format_datetime(time)}</span>
          </td>
        </tr>
      HTML
    end

    def generate_failed_row(execution)
      job = execution.job
      <<-HTML
        <tr>
          <td><a href="#{job_path(job)}" class="job-class-link">#{job.class_name}</a></td>
          <td>#{queue_link(job.queue_name)}</td>
          <td><div class="error-message">#{escape_html(execution.error.to_s.truncate(100))}</div></td>
          <td>
            <span class="job-timestamp">#{format_datetime(execution.created_at)}</span>
          </td>
        </tr>
      HTML
    end

    def generate_completed_row(job)
      <<-HTML
        <tr>
          <td><a href="#{job_path(job)}" class="job-class-link">#{job.class_name}</a></td>
          <td>#{queue_link(job.queue_name)}</td>
          <td>#{format_arguments(job.arguments)}</td>
          <td>
            <span class="job-timestamp">#{format_datetime(job.finished_at)}</span>
          </td>
        </tr>
      HTML
    end

    def generate_recurring_row(task)
      <<-HTML
        <tr>
          <td><strong>#{task.key}</strong></td>
          <td>#{task.class_name || '-'}</td>
          <td><code>#{task.schedule}</code></td>
          <td>#{queue_link(task.queue_name)}</td>
        </tr>
      HTML
    end

    def total_count
      @total_count ||= @results.values.sum(&:size)
    end

    def escape_html(text)
      text.to_s.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;').gsub('"', '&quot;')
    end
  end
end
