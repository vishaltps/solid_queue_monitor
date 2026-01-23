# frozen_string_literal: true

module SolidQueueMonitor
  class WorkersPresenter < BasePresenter
    HEARTBEAT_STALE_THRESHOLD = 5.minutes
    HEARTBEAT_DEAD_THRESHOLD = 10.minutes

    def initialize(processes, current_page: 1, total_pages: 1, filters: {})
      @processes = processes.to_a # Load records once to avoid multiple queries
      @current_page = current_page
      @total_pages = total_pages
      @filters = filters
      preload_claimed_data
      calculate_summary_stats
    end

    def render
      section_wrapper('Workers', generate_content)
    end

    private

    def generate_content
      generate_filter_form + generate_summary + generate_table_or_empty + generate_pagination(@current_page, @total_pages)
    end

    def generate_filter_form
      <<-HTML
        <div class="filter-form-container">
          <form method="get" action="#{workers_path}" class="filter-form">
            <div class="filter-group">
              <label for="kind">Kind:</label>
              <select name="kind" id="kind">
                <option value="">All</option>
                #{kind_options}
              </select>
            </div>

            <div class="filter-group">
              <label for="hostname">Hostname:</label>
              <input type="text" name="hostname" id="hostname" value="#{@filters[:hostname]}" placeholder="Filter by hostname">
            </div>

            <div class="filter-group">
              <label for="status">Status:</label>
              <select name="status" id="status">
                <option value="">All</option>
                <option value="healthy" #{@filters[:status] == 'healthy' ? 'selected' : ''}>Healthy</option>
                <option value="stale" #{@filters[:status] == 'stale' ? 'selected' : ''}>Stale</option>
                <option value="dead" #{@filters[:status] == 'dead' ? 'selected' : ''}>Dead</option>
              </select>
            </div>

            <div class="filter-actions">
              <button type="submit" class="filter-button">Apply Filters</button>
              <a href="#{workers_path}" class="reset-button">Reset</a>
            </div>
          </form>
        </div>
      HTML
    end

    def kind_options
      kinds = %w[Worker Dispatcher Scheduler]
      kinds.map do |kind|
        selected = @filters[:kind] == kind ? 'selected' : ''
        "<option value=\"#{kind}\" #{selected}>#{kind}</option>"
      end.join
    end

    def calculate_summary_stats
      all_processes = all_processes_for_summary
      @total_count = all_processes.count
      @healthy_count = all_processes.count { |p| worker_status(p) == :healthy }
      @stale_count = all_processes.count { |p| worker_status(p) == :stale }
      @dead_count = all_processes.count { |p| worker_status(p) == :dead }
    end

    def generate_summary
      <<-HTML
        <div class="workers-summary">
          <div class="summary-card">
            <span class="summary-label">Total Processes</span>
            <span class="summary-value">#{@total_count}</span>
          </div>
          <div class="summary-card summary-healthy">
            <span class="summary-label">Healthy</span>
            <span class="summary-value">#{@healthy_count}</span>
          </div>
          <div class="summary-card summary-stale">
            <span class="summary-label">Stale</span>
            <span class="summary-value">#{@stale_count}</span>
          </div>
          <div class="summary-card summary-dead">
            <span class="summary-label">Dead</span>
            <span class="summary-value">#{@dead_count}</span>
            #{prune_all_link}
          </div>
        </div>
      HTML
    end

    def prune_all_link
      return '' if @dead_count.zero?

      <<-HTML
        <a href="#" class="summary-action"
           onclick="if(confirm('Remove all #{@dead_count} dead process#{@dead_count > 1 ? 'es' : ''}? This will clean up processes that have stopped sending heartbeats.')) { document.getElementById('prune-all-form').submit(); } return false;">
          Prune all
        </a>
        <form id="prune-all-form" action="#{prune_workers_path}" method="post" style="display: none;"></form>
      HTML
    end

    def all_processes_for_summary
      @all_processes_for_summary ||= SolidQueue::Process.all.to_a
    end

    def generate_table_or_empty
      if @processes.empty?
        generate_empty_state
      else
        generate_table
      end
    end

    def generate_empty_state
      <<-HTML
        <div class="empty-state">
          <p>No worker processes found.</p>
          <p class="empty-state-hint">Workers will appear here when Solid Queue processes are running.</p>
        </div>
      HTML
    end

    def generate_table
      <<-HTML
        <div class="table-container">
          <table>
            <thead>
              <tr>
                <th>Kind</th>
                <th>Hostname</th>
                <th>PID</th>
                <th>Queues</th>
                <th>Last Heartbeat</th>
                <th>Status</th>
                <th>Jobs Processing</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              #{@processes.map { |process| generate_row(process) }.join}
            </tbody>
          </table>
        </div>
      HTML
    end

    def generate_row(process)
      status = worker_status(process)
      row_class = case status
                  when :dead then 'worker-dead'
                  when :stale then 'worker-stale'
                  else ''
                  end

      <<-HTML
        <tr class="#{row_class}">
          <td>#{kind_badge(process.kind)}</td>
          <td>#{hostname(process)}</td>
          <td><code>#{process.pid}</code></td>
          <td>#{queues_display(process)}</td>
          <td>#{format_heartbeat(process.last_heartbeat_at)}</td>
          <td>#{status_badge(status)}</td>
          <td>#{jobs_processing(process)}</td>
          <td class="actions-cell">#{action_button(process, status)}</td>
        </tr>
      HTML
    end

    def action_button(process, status)
      return '<span class="action-placeholder">-</span>' unless status == :dead

      <<-HTML
        <form action="#{remove_worker_path(id: process.id)}" method="post" class="inline-form"
              onsubmit="return confirm('Remove this dead process from the registry?');">
          <button type="submit" class="action-button discard-button" title="Remove dead process">
            Remove
          </button>
        </form>
      HTML
    end

    def kind_badge(kind)
      badge_class = case kind
                    when 'Worker' then 'kind-worker'
                    when 'Dispatcher' then 'kind-dispatcher'
                    when 'Scheduler' then 'kind-scheduler'
                    else 'kind-other'
                    end
      "<span class=\"kind-badge #{badge_class}\">#{kind}</span>"
    end

    def hostname(process)
      process.hostname || parse_metadata(process)['hostname'] || '-'
    end

    def queues_display(process)
      metadata = parse_metadata(process)
      queues = metadata['queues']

      return '-' if queues.nil?

      # Handle string queues (e.g., "*" for all queues)
      if queues.is_a?(String)
        return "<code class=\"queue-tag\">#{queues == '*' ? 'All Queues' : queues}</code>"
      end

      return '-' if queues.empty?

      if queues.length <= 3
        queues.map { |q| "<code class=\"queue-tag\">#{q}</code>" }.join(' ')
      else
        visible = queues.first(2).map { |q| "<code class=\"queue-tag\">#{q}</code>" }.join(' ')
        "#{visible} <span class=\"queue-more\">+#{queues.length - 2} more</span>"
      end
    end

    def format_heartbeat(heartbeat_at)
      return '-' unless heartbeat_at

      time_ago = time_ago_in_words(heartbeat_at)
      "<span title=\"#{heartbeat_at.strftime('%Y-%m-%d %H:%M:%S')}\">#{time_ago} ago</span>"
    end

    def worker_status(process)
      return :dead unless process.last_heartbeat_at

      time_since_heartbeat = Time.current - process.last_heartbeat_at

      if time_since_heartbeat > HEARTBEAT_DEAD_THRESHOLD
        :dead
      elsif time_since_heartbeat > HEARTBEAT_STALE_THRESHOLD
        :stale
      else
        :healthy
      end
    end

    def status_badge(status)
      case status
      when :healthy
        '<span class="status-badge status-healthy">Healthy</span>'
      when :stale
        '<span class="status-badge status-stale">Stale</span>'
      when :dead
        '<span class="status-badge status-dead">Dead</span>'
      end
    end

    def jobs_processing(process)
      count = @claimed_counts[process.id] || 0

      if count.zero?
        '<span class="jobs-idle">Idle</span>'
      else
        jobs = @claimed_jobs[process.id] || []
        job_names = jobs.map(&:class_name).uniq.first(3)

        tooltip = jobs.first(10).map { |j| "#{j.class_name} (ID: #{j.id})" }.join("&#10;")

        <<-HTML
          <span class="jobs-processing" title="#{tooltip}">
            #{count} job#{count > 1 ? 's' : ''}
            <span class="job-names">(#{job_names.join(', ')}#{jobs.length > 3 ? '...' : ''})</span>
          </span>
        HTML
      end
    end

    def preload_claimed_data
      return if @processes.empty?

      process_ids = @processes.map(&:id)

      # Preload claimed execution counts
      @claimed_counts = SolidQueue::ClaimedExecution
                        .where(process_id: process_ids)
                        .group(:process_id)
                        .count

      # Preload claimed jobs for processes that have any
      claimed_executions = SolidQueue::ClaimedExecution
                           .includes(:job)
                           .where(process_id: process_ids)

      @claimed_jobs = claimed_executions.each_with_object({}) do |execution, hash|
        hash[execution.process_id] ||= []
        hash[execution.process_id] << execution.job
      end
    end

    def parse_metadata(process)
      @parsed_metadata ||= {}
      @parsed_metadata[process.id] ||= begin
        return {} unless process.metadata

        if process.metadata.is_a?(String)
          JSON.parse(process.metadata)
        else
          process.metadata
        end
      rescue JSON::ParserError
        {}
      end
    end
  end
end
