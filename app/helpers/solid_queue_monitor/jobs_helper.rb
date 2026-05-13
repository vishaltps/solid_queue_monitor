# frozen_string_literal: true

module SolidQueueMonitor
  module JobsHelper
    def format_arguments(arguments)
      return '-' if arguments.blank?

      formatted = unwrap_arguments(arguments)
      if formatted.length <= 50
        tag.code(formatted, class: 'args-single-line')
      else
        tag.div(tag.code(formatted, class: 'args-content'), class: 'args-container')
      end
    end

    def format_hash(hash)
      return '-' if hash.blank?

      parts = hash.map do |key, value|
        safe_join([tag.strong("#{key}:"), ' ', truncate(value.to_s, length: 50)])
      end
      tag.code(safe_join(parts, ', '))
    end

    def job_status(job)
      SolidQueueMonitor::StatusCalculator.new(job).calculate
    end

    def job_status_badge(job)
      status = job_status(job)
      tag.span(status, class: "status-badge status-#{status}")
    end

    def mini_job_status_badge(job)
      status = mini_job_status(job)

      labels = {
        failed: 'Failed',
        completed: 'Completed',
        in_progress: 'In Progress',
        scheduled: 'Scheduled',
        ready: 'Ready',
        pending: 'Pending'
      }
      css_status = status == :ready ? :pending : status
      tag.span(labels[status], class: "mini-status-badge status-#{css_status}")
    end

    def failed_error_message(error)
      parsed_failed_error(error)[:message].to_s
    end

    def parsed_failed_error(error)
      return { type: 'Unknown', message: 'Unknown error', backtrace: [] } unless error

      error_hash = deserialize_failed_error(error)
      {
        type: failed_error_type(error_hash),
        message: failed_error_text(error_hash),
        backtrace: failed_error_backtrace(error_hash)
      }
    end

    private

    def mini_job_status(job)
      return :failed if job.respond_to?(:failed_execution) && job.failed_execution.present?
      return :in_progress if job.respond_to?(:claimed_execution) && job.claimed_execution.present?
      return :scheduled if job.respond_to?(:scheduled_execution) && job.scheduled_execution.present?
      return :ready if job.respond_to?(:ready_execution) && job.ready_execution.present?
      return :completed if job.finished_at

      :pending
    end

    def failed_error_type(error_hash)
      error_hash['exception_class'] || error_hash[:exception_class] ||
        error_hash['error_class'] || error_hash[:error_class] ||
        error_hash['class'] || error_hash[:class] || 'Error'
    end

    def failed_error_text(error_hash)
      error_hash['message'] || error_hash[:message] ||
        error_hash['error'] || error_hash[:error] || 'Unknown error'
    end

    def failed_error_backtrace(error_hash)
      Array(error_hash['backtrace'] || error_hash[:backtrace] || error_hash['stack_trace'] || error_hash[:stack_trace])
    end

    def deserialize_failed_error(error)
      return error if error.is_a?(Hash)
      return { 'message' => error.to_s } unless error.is_a?(String)

      JSON.parse(error)
    rescue JSON::ParserError
      { 'message' => error }
    end

    def unwrap_arguments(arguments)
      payload = if arguments.is_a?(Hash) && arguments['arguments'].present?
                  format_job_arguments(arguments)
                elsif wrapped_job_arguments?(arguments)
                  format_job_arguments(arguments.first)
                else
                  arguments.inspect
                end
      payload.to_s
    end

    def wrapped_job_arguments?(arguments)
      arguments.is_a?(Array) &&
        arguments.length == 1 &&
        arguments.first.is_a?(Hash) &&
        arguments.first['arguments'].present?
    end

    def format_job_arguments(job_data)
      args = if ruby2_keywords_payload?(job_data)
               job_data['arguments'].first.except('_aj_ruby2_keywords')
             else
               job_data['arguments']
             end

      args.inspect
    end

    def ruby2_keywords_payload?(job_data)
      job_data['arguments'].is_a?(Array) &&
        job_data['arguments'].first.is_a?(Hash) &&
        job_data['arguments'].first['_aj_ruby2_keywords'].present?
    end
  end
end
