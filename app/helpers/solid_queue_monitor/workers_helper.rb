# frozen_string_literal: true

module SolidQueueMonitor
  module WorkersHelper
    HEARTBEAT_STALE_THRESHOLD = 5.minutes
    HEARTBEAT_DEAD_THRESHOLD = 10.minutes

    def worker_status(process)
      return :dead unless process.last_heartbeat_at

      time_since_heartbeat = Time.current - process.last_heartbeat_at
      return :dead if time_since_heartbeat > HEARTBEAT_DEAD_THRESHOLD
      return :stale if time_since_heartbeat > HEARTBEAT_STALE_THRESHOLD

      :healthy
    end

    def worker_row_class(process)
      case worker_status(process)
      when :dead then 'worker-dead'
      when :stale then 'worker-stale'
      else ''
      end
    end

    def worker_kind_badge(kind)
      badge_class = case kind
                    when 'Worker' then 'kind-worker'
                    when 'Dispatcher' then 'kind-dispatcher'
                    when 'Scheduler' then 'kind-scheduler'
                    else 'kind-other'
                    end
      tag.span(kind, class: class_names('kind-badge', badge_class))
    end

    def worker_hostname(process)
      process.hostname || worker_metadata(process)['hostname'] || '-'
    end

    def worker_queues(process)
      queues = worker_metadata(process)['queues']
      return '-' if queues.nil?

      return tag.code(queues == '*' ? 'All Queues' : queues, class: 'queue-tag') if queues.is_a?(String)
      return '-' if queues.empty?

      if queues.length <= 3
        safe_join(queues.map { |queue| tag.code(queue, class: 'queue-tag') }, ' ')
      else
        visible = safe_join(queues.first(2).map { |queue| tag.code(queue, class: 'queue-tag') }, ' ')
        safe_join([visible, tag.span("+#{queues.length - 2} more", class: 'queue-more')], ' ')
      end
    end

    def worker_heartbeat(heartbeat_at)
      return '-' unless heartbeat_at

      tag.span("#{time_ago_in_words(heartbeat_at)} ago", title: heartbeat_at.strftime('%Y-%m-%d %H:%M:%S'))
    end

    def worker_status_badge(status)
      tag.span(status.to_s.capitalize, class: "status-badge status-#{status}")
    end

    def worker_jobs_processing(process, claimed_counts:, claimed_jobs:)
      count = claimed_counts[process.id] || 0
      return tag.span('Idle', class: 'jobs-idle') if count.zero?

      jobs = claimed_jobs[process.id] || []
      job_names = jobs.map(&:class_name).uniq.first(3)
      tooltip = jobs.first(10).map { |job| "#{job.class_name} (ID: #{job.id})" }.join("\n")
      label = "#{count} job#{'s' if count > 1}"
      names = "(#{job_names.join(', ')}#{'...' if jobs.length > 3})"

      tag.span(class: 'jobs-processing', title: tooltip) do
        safe_join([label, tag.span(names, class: 'job-names')], ' ')
      end
    end

    def worker_metadata(process)
      return {} unless process.metadata

      process.metadata.is_a?(String) ? JSON.parse(process.metadata) : process.metadata
    rescue JSON::ParserError
      {}
    end
  end
end
