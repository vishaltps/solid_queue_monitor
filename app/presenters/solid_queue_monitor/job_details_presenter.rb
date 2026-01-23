# frozen_string_literal: true

module SolidQueueMonitor
  class JobDetailsPresenter < BasePresenter
    def initialize(job, failed_execution: nil, claimed_execution: nil, scheduled_execution: nil,
                   recent_executions: [], back_path: nil)
      @job = job
      @failed_execution = failed_execution
      @claimed_execution = claimed_execution
      @scheduled_execution = scheduled_execution
      @recent_executions = recent_executions
      @back_path = back_path
      calculate_timing
    end

    def render
      <<-HTML
        <div class="job-details-page">
          #{render_back_link}
          #{render_header}
          #{render_timeline}
          #{render_timing_cards}
          #{render_error_section if @failed_execution}
          #{render_arguments_section}
          #{render_details_section}
          #{render_worker_section if @claimed_execution}
          #{render_recent_executions}
          #{render_raw_data_section}
        </div>
      HTML
    end

    private

    def calculate_timing
      @created_at = @job.created_at
      @scheduled_at = @job.scheduled_at || @scheduled_execution&.scheduled_at
      @started_at = @claimed_execution&.created_at
      @finished_at = @job.finished_at
      @failed_at = @failed_execution&.created_at

      # Calculate durations
      @queue_wait_time = calculate_queue_wait
      @execution_time = calculate_execution_time
      @total_time = calculate_total_time
    end

    def calculate_queue_wait
      return nil unless @started_at && @created_at

      @started_at - @created_at
    end

    def calculate_execution_time
      end_time = @finished_at || @failed_at
      return nil unless @started_at && end_time

      end_time - @started_at
    end

    def calculate_total_time
      end_time = @finished_at || @failed_at
      return nil unless @created_at && end_time

      end_time - @created_at
    end

    def job_status
      return :failed if @failed_execution
      return :in_progress if @claimed_execution
      return :scheduled if @scheduled_execution || @job.scheduled_at&.future?
      return :completed if @job.finished_at

      :pending
    end

    def status_label
      {
        failed: 'Failed',
        in_progress: 'In Progress',
        scheduled: 'Scheduled',
        completed: 'Completed',
        pending: 'Pending'
      }[job_status]
    end

    def status_class
      {
        failed: 'status-failed',
        in_progress: 'status-in-progress',
        scheduled: 'status-scheduled',
        completed: 'status-completed',
        pending: 'status-pending'
      }[job_status]
    end

    def render_back_link
      <<-HTML
        <div class="job-back-link">
          <a href="#{@back_path}" class="back-link">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M19 12H5M12 19l-7-7 7-7"/>
            </svg>
            Back
          </a>
        </div>
      HTML
    end

    def render_header
      <<-HTML
        <div class="job-header">
          <div class="job-header-main">
            <h1 class="job-title">#{@job.class_name}</h1>
            <span class="job-status-badge #{status_class}">#{status_label}</span>
          </div>
          <div class="job-header-meta">
            <span class="job-queue">#{queue_link(@job.queue_name)}</span>
            <span class="job-separator">•</span>
            <span class="job-priority">Priority #{@job.priority}</span>
            <span class="job-separator">•</span>
            <span class="job-id">Job ##{@job.id}</span>
          </div>
          #{render_actions}
        </div>
      HTML
    end

    def render_actions
      actions = []

      if @failed_execution
        actions << <<-HTML
          <form action="#{retry_failed_job_path(id: @failed_execution.id)}" method="post" class="inline-form">
            <input type="hidden" name="redirect_to" value="#{job_path(@job)}">
            <button type="submit" class="action-button retry-button">Retry</button>
          </form>
        HTML

        actions << <<-HTML
          <form action="#{discard_failed_job_path(id: @failed_execution.id)}" method="post" class="inline-form"
                onsubmit="return confirm('Are you sure you want to discard this job?');">
            <input type="hidden" name="redirect_to" value="#{failed_jobs_path}">
            <button type="submit" class="action-button discard-button">Discard</button>
          </form>
        HTML
      end

      if @scheduled_execution
        actions << <<-HTML
          <form action="#{execute_scheduled_job_path(id: @scheduled_execution.id)}" method="post" class="inline-form">
            <input type="hidden" name="redirect_to" value="#{scheduled_jobs_path}">
            <button type="submit" class="action-button retry-button">Execute Now</button>
          </form>
        HTML
      end

      return '' if actions.empty?

      <<-HTML
        <div class="job-actions">
          #{actions.join}
        </div>
      HTML
    end

    def render_timeline
      events = build_timeline_events
      return '' if events.size < 2

      <<-HTML
        <div class="job-section">
          <h3 class="section-title">Timeline</h3>
          <div class="job-timeline">
            <div class="timeline-track">
              #{render_timeline_events(events)}
            </div>
          </div>
        </div>
      HTML
    end

    def build_timeline_events
      events = []
      events << { label: 'Created', time: @created_at, status: :done } if @created_at
      events << { label: 'Scheduled', time: @scheduled_at, status: :done } if @scheduled_at && @scheduled_at != @created_at
      events << { label: 'Started', time: @started_at, status: :done } if @started_at

      case job_status
      when :completed
        events << { label: 'Completed', time: @finished_at, status: :success }
      when :failed
        events << { label: 'Failed', time: @failed_at, status: :failed }
      when :in_progress
        events << { label: 'Running...', time: nil, status: :active }
      end

      events
    end

    def render_timeline_events(events)
      total = events.size
      events.map.with_index do |event, index|
        is_last = index == total - 1
        status_class = "timeline-#{event[:status]}"

        <<-HTML
          <div class="timeline-event #{status_class}">
            <div class="timeline-dot"></div>
            #{is_last ? '' : '<div class="timeline-line"></div>'}
            <div class="timeline-content">
              <div class="timeline-label">#{event[:label]}</div>
              <div class="timeline-time">#{event[:time] ? format_datetime(event[:time]) : ''}</div>
            </div>
          </div>
        HTML
      end.join
    end

    def render_timing_cards
      <<-HTML
        <div class="timing-cards">
          #{render_timing_card('Queue Wait', @queue_wait_time, queue_wait_indicator, timing_unavailable_reason(:queue_wait))}
          #{render_timing_card('Execution', @execution_time, execution_indicator, timing_unavailable_reason(:execution))}
          #{render_timing_card('Total Time', @total_time, nil, nil)}
        </div>
      HTML
    end

    def render_timing_card(label, duration, indicator, unavailable_reason)
      formatted = duration ? format_duration(duration) : '-'
      indicator_html = indicator ? "<div class=\"timing-indicator #{indicator[:class]}\">#{indicator[:label]}</div>" : ''
      tooltip = unavailable_reason && !duration ? " title=\"#{unavailable_reason}\"" : ''

      <<-HTML
        <div class="timing-card"#{tooltip}>
          <div class="timing-value">#{formatted}</div>
          <div class="timing-label">#{label}</div>
          #{indicator_html}
        </div>
      HTML
    end

    def timing_unavailable_reason(timing_type)
      return nil if @claimed_execution # In-progress jobs have all timing data
      return nil unless %i[queue_wait execution].include?(timing_type)

      if @failed_execution || @job.finished_at
        'Not available - execution record deleted after job completed'
      else
        'Available once job starts processing'
      end
    end

    def queue_wait_indicator
      return nil unless @queue_wait_time

      if @queue_wait_time > 300 # > 5 minutes
        { class: 'indicator-warning', label: 'High' }
      elsif @queue_wait_time > 60 # > 1 minute
        { class: 'indicator-normal', label: 'Normal' }
      else
        { class: 'indicator-good', label: 'Fast' }
      end
    end

    def execution_indicator
      return nil unless @execution_time

      if @execution_time > 60 # > 1 minute
        { class: 'indicator-warning', label: 'Slow' }
      elsif @execution_time > 10 # > 10 seconds
        { class: 'indicator-normal', label: 'Normal' }
      else
        { class: 'indicator-good', label: 'Fast' }
      end
    end

    def format_duration(seconds)
      return '-' unless seconds

      if seconds < 1
        "#{(seconds * 1000).round}ms"
      elsif seconds < 60
        "#{seconds.round(1)}s"
      elsif seconds < 3600
        minutes = (seconds / 60).floor
        secs = (seconds % 60).round
        "#{minutes}m #{secs}s"
      else
        hours = (seconds / 3600).floor
        minutes = ((seconds % 3600) / 60).floor
        "#{hours}h #{minutes}m"
      end
    end

    def render_error_section
      error = parse_error(@failed_execution.error)

      <<-HTML
        <div class="job-section error-section">
          <div class="section-header">
            <h3 class="section-title">Error</h3>
            <button class="copy-button" onclick="copyToClipboard('error-content')">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect>
                <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path>
              </svg>
              Copy
            </button>
          </div>
          <div id="error-content">
            <div class="error-type">#{error[:type]}</div>
            <div class="error-message-box">#{error[:message]}</div>
          </div>
          #{render_backtrace(error[:backtrace])}
        </div>
      HTML
    end

    def render_backtrace(backtrace)
      return '' if backtrace.blank?

      lines = backtrace.is_a?(Array) ? backtrace : backtrace.to_s.split("\n")
      app_lines = lines.select { |line| line.include?('/app/') || line.include?('/lib/') }

      <<-HTML
        <div class="backtrace-section">
          <div class="backtrace-header">
            <span class="backtrace-title">Backtrace</span>
            <div class="backtrace-toggle">
              <button class="toggle-btn active" data-target="app-backtrace" onclick="showBacktrace('app')">App Only</button>
              <button class="toggle-btn" data-target="full-backtrace" onclick="showBacktrace('full')">Full</button>
            </div>
          </div>
          <pre class="backtrace-content" id="app-backtrace">#{format_backtrace_lines(app_lines.presence || lines.first(5))}</pre>
          <pre class="backtrace-content" id="full-backtrace" style="display: none;">#{format_backtrace_lines(lines)}</pre>
        </div>
        <script>
          function showBacktrace(type) {
            document.getElementById('app-backtrace').style.display = type === 'app' ? 'block' : 'none';
            document.getElementById('full-backtrace').style.display = type === 'full' ? 'block' : 'none';
            document.querySelectorAll('.backtrace-toggle .toggle-btn').forEach(btn => {
              btn.classList.toggle('active', btn.dataset.target === type + '-backtrace');
            });
          }
        </script>
      HTML
    end

    def format_backtrace_lines(lines)
      lines.map.with_index do |line, index|
        "<span class=\"backtrace-line\"><span class=\"line-number\">#{index + 1}.</span> #{CGI.escapeHTML(line.to_s.strip)}</span>"
      end.join("\n")
    end

    def parse_error(error)
      return { type: 'Unknown', message: 'Unknown error', backtrace: [] } unless error

      # Convert to hash if it's a serialized string
      error_hash = deserialize_error(error)

      {
        type: extract_error_type(error_hash),
        message: extract_error_message(error_hash),
        backtrace: extract_backtrace(error_hash)
      }
    end

    def deserialize_error(error)
      return error if error.is_a?(Hash)

      if error.is_a?(String)
        # Try JSON first
        if error.strip.start_with?('{')
          begin
            return JSON.parse(error)
          rescue JSON::ParserError
            # Continue to try other formats
          end
        end

        # Try YAML (SolidQueue may use YAML serialization)
        begin
          parsed = YAML.safe_load(error, permitted_classes: [Symbol])
          return parsed if parsed.is_a?(Hash)
        rescue StandardError
          # Continue with string
        end

        # Return as simple error hash
        { 'message' => error }
      else
        { 'message' => error.to_s }
      end
    end

    def extract_error_type(error_hash)
      error_hash['exception_class'] || error_hash[:exception_class] ||
        error_hash['error_class'] || error_hash[:error_class] ||
        error_hash['class'] || error_hash[:class] || 'Error'
    end

    def extract_error_message(error_hash)
      error_hash['message'] || error_hash[:message] ||
        error_hash['error'] || error_hash[:error] || 'Unknown error'
    end

    def extract_backtrace(error_hash)
      bt = error_hash['backtrace'] || error_hash[:backtrace] ||
           error_hash['stack_trace'] || error_hash[:stack_trace] || []

      # Ensure it's an array
      return bt if bt.is_a?(Array)
      return bt.split("\n") if bt.is_a?(String) && bt.present?

      []
    end

    def render_arguments_section
      args = @job.arguments
      formatted_args = format_job_arguments_pretty(args)

      <<-HTML
        <div class="job-section">
          <div class="section-header">
            <h3 class="section-title">Arguments</h3>
            <div class="section-actions">
              <button class="copy-button" onclick="copyToClipboard('arguments-content')">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect>
                  <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path>
                </svg>
                Copy
              </button>
            </div>
          </div>
          <pre class="arguments-content" id="arguments-content">#{CGI.escapeHTML(formatted_args)}</pre>
        </div>
      HTML
    end

    def format_job_arguments_pretty(args)
      return '-' if args.blank?

      JSON.pretty_generate(args)
    rescue JSON::GeneratorError
      args.inspect
    end

    def render_details_section
      <<-HTML
        <div class="job-section">
          <h3 class="section-title">Job Details</h3>
          <div class="details-grid">
            <div class="detail-row">
              <span class="detail-label">Class</span>
              <span class="detail-value">#{@job.class_name}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">Queue</span>
              <span class="detail-value">#{queue_link(@job.queue_name, css_class: 'queue-badge')}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">Priority</span>
              <span class="detail-value">#{@job.priority}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">Active Job ID</span>
              <span class="detail-value detail-mono">#{@job.active_job_id || '-'}</span>
            </div>
            #{render_concurrency_key}
            <div class="detail-row">
              <span class="detail-label">Created At</span>
              <span class="detail-value">#{format_datetime(@job.created_at)}</span>
            </div>
            #{render_scheduled_at}
            #{render_finished_at}
            #{render_failed_at}
          </div>
        </div>
      HTML
    end

    def render_concurrency_key
      return '' unless @job.concurrency_key.present?

      <<-HTML
        <div class="detail-row">
          <span class="detail-label">Concurrency Key</span>
          <span class="detail-value detail-mono">#{@job.concurrency_key}</span>
        </div>
      HTML
    end

    def render_scheduled_at
      return '' unless @scheduled_at

      <<-HTML
        <div class="detail-row">
          <span class="detail-label">Scheduled At</span>
          <span class="detail-value">#{format_datetime(@scheduled_at)}</span>
        </div>
      HTML
    end

    def render_finished_at
      return '' unless @job.finished_at

      <<-HTML
        <div class="detail-row">
          <span class="detail-label">Finished At</span>
          <span class="detail-value">#{format_datetime(@job.finished_at)}</span>
        </div>
      HTML
    end

    def render_failed_at
      return '' unless @failed_at

      <<-HTML
        <div class="detail-row">
          <span class="detail-label">Failed At</span>
          <span class="detail-value">#{format_datetime(@failed_at)}</span>
        </div>
      HTML
    end

    def render_worker_section
      process = @claimed_execution.instance_variable_get(:@process)
      return '' unless process

      <<-HTML
        <div class="job-section">
          <h3 class="section-title">Worker</h3>
          <div class="details-grid">
            <div class="detail-row">
              <span class="detail-label">Hostname</span>
              <span class="detail-value">#{process.hostname}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">PID</span>
              <span class="detail-value">#{process.pid}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">Process Type</span>
              <span class="detail-value">#{process.kind}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">Started At</span>
              <span class="detail-value">#{format_datetime(@claimed_execution.created_at)}</span>
            </div>
          </div>
        </div>
      HTML
    end

    def render_recent_executions
      return '' if @recent_executions.empty?

      <<-HTML
        <div class="job-section">
          <div class="section-header">
            <h3 class="section-title">Recent Executions</h3>
            <span class="section-subtitle">Other #{@job.class_name} jobs</span>
          </div>
          <div class="table-container">
            <table class="recent-executions-table">
              <thead>
                <tr>
                  <th>Status</th>
                  <th>Arguments</th>
                  <th>Created</th>
                  <th>Duration</th>
                </tr>
              </thead>
              <tbody>
                #{@recent_executions.map { |job| render_execution_row(job) }.join}
              </tbody>
            </table>
          </div>
        </div>
      HTML
    end

    def render_execution_row(job)
      status = determine_job_status(job)
      status_badge = render_status_badge(status)
      duration = calculate_job_duration(job)
      args_preview = truncate_arguments(job.arguments)

      <<-HTML
        <tr>
          <td>#{status_badge}</td>
          <td class="args-preview"><a href="#{job_path(job)}">#{args_preview}</a></td>
          <td>#{time_ago_in_words(job.created_at)} ago</td>
          <td>#{duration}</td>
        </tr>
      HTML
    end

    def determine_job_status(job)
      return :failed if job.failed_execution.present?
      return :in_progress if job.claimed_execution.present?
      return :scheduled if job.scheduled_execution.present?
      return :ready if job.ready_execution.present?
      return :completed if job.finished_at

      :pending
    end

    def render_status_badge(status)
      labels = {
        failed: 'Failed',
        completed: 'Completed',
        in_progress: 'In Progress',
        scheduled: 'Scheduled',
        ready: 'Ready',
        pending: 'Pending'
      }
      classes = {
        failed: 'status-failed',
        completed: 'status-completed',
        in_progress: 'status-in-progress',
        scheduled: 'status-scheduled',
        ready: 'status-pending',
        pending: 'status-pending'
      }

      "<span class=\"mini-status-badge #{classes[status]}\">#{labels[status]}</span>"
    end

    def calculate_job_duration(job)
      return '-' unless job.finished_at || job.failed_execution&.created_at

      end_time = job.finished_at || job.failed_execution&.created_at
      format_duration(end_time - job.created_at)
    end

    def truncate_arguments(args)
      return '-' if args.blank?

      preview = args.inspect.truncate(60)
      CGI.escapeHTML(preview)
    end

    def render_raw_data_section
      <<-HTML
        <div class="job-section collapsible-section">
          <div class="section-header collapsible-header" onclick="toggleSection(this)">
            <div class="collapsible-title">
              <svg class="collapse-icon" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="9 18 15 12 9 6"></polyline>
              </svg>
              <h3 class="section-title">Raw Data</h3>
            </div>
            <button class="copy-button" onclick="event.stopPropagation(); copyToClipboard('raw-data-content')">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect>
                <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path>
              </svg>
              Copy
            </button>
          </div>
          <div class="collapsible-content" style="display: none;">
            <pre class="raw-data-content" id="raw-data-content">#{CGI.escapeHTML(JSON.pretty_generate(@job.attributes))}</pre>
          </div>
        </div>
        <script>
          function toggleSection(header) {
            const content = header.nextElementSibling;
            const icon = header.querySelector('.collapse-icon');
            if (content.style.display === 'none') {
              content.style.display = 'block';
              icon.style.transform = 'rotate(90deg)';
            } else {
              content.style.display = 'none';
              icon.style.transform = 'rotate(0deg)';
            }
          }

          function copyToClipboard(elementId) {
            const element = document.getElementById(elementId);
            const text = element.innerText || element.textContent;
            navigator.clipboard.writeText(text).then(() => {
              const btn = event.target.closest('.copy-button');
              const originalText = btn.innerHTML;
              btn.innerHTML = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"></polyline></svg> Copied!';
              setTimeout(() => { btn.innerHTML = originalText; }, 2000);
            });
          }
        </script>
      HTML
    end
  end
end
