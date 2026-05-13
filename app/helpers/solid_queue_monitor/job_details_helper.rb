# frozen_string_literal: true

module SolidQueueMonitor
  module JobDetailsHelper
    def detail_job_status(job:, failed_execution:, claimed_execution:, scheduled_execution:)
      return :failed if failed_execution
      return :in_progress if claimed_execution
      return :scheduled if scheduled_execution || job.scheduled_at&.future?
      return :completed if job.finished_at

      :pending
    end

    def detail_status_label(status = detail_job_status)
      {
        failed: 'Failed',
        in_progress: 'In Progress',
        scheduled: 'Scheduled',
        completed: 'Completed',
        pending: 'Pending'
      }[status]
    end

    def detail_status_class(status = detail_job_status)
      "status-#{status.to_s.tr('_', '-')}"
    end

    def detail_duration(seconds)
      return '-' unless seconds
      return "#{(seconds * 1000).round}ms" if seconds < 1
      return "#{seconds.round(1)}s" if seconds < 60
      return "#{(seconds / 60).floor}m #{(seconds % 60).round}s" if seconds < 3600

      "#{(seconds / 3600).floor}h #{((seconds % 3600) / 60).floor}m"
    end

    def detail_timing(job:, claimed_execution:, failed_execution:)
      created_at = job.created_at
      started_at = claimed_execution&.created_at
      finished_at = job.finished_at
      failed_at = failed_execution&.created_at
      end_time = finished_at || failed_at

      {
        queue_wait: started_at && created_at ? started_at - created_at : nil,
        execution: started_at && end_time ? end_time - started_at : nil,
        total: created_at && end_time ? end_time - created_at : nil
      }
    end

    def pretty_arguments(args)
      return '-' if args.blank?

      JSON.pretty_generate(args)
    rescue JSON::GeneratorError
      args.inspect
    end

    def recent_job_duration(job)
      end_time = job.finished_at || job.failed_execution&.created_at
      return '-' unless end_time

      detail_duration(end_time - job.created_at)
    end
  end
end
