# frozen_string_literal: true

module SolidQueueMonitor
  class BaseController < SolidQueueMonitor::ApplicationController
    def paginate(relation)
      PaginationService.new(relation, current_page, per_page).paginate
    end

    def render_page(title, content, search_query: nil)
      # Get flash message from instance variable (set by set_flash_message) or session
      message = @flash_message
      message_type = @flash_type

      # Try to get from session as fallback, but don't fail if session unavailable
      begin
        message ||= session[:flash_message]
        message_type ||= session[:flash_type]

        # Clear the flash message from session after using it
        session.delete(:flash_message) if message
        session.delete(:flash_type) if message_type
      rescue StandardError
        # Session not available (e.g., no session middleware in tests)
      end

      html = SolidQueueMonitor::HtmlGenerator.new(
        title: title,
        content: content,
        message: message,
        message_type: message_type,
        search_query: search_query
      ).generate

      render html: html.html_safe
    end

    def current_page
      (params[:page] || 1).to_i
    end

    def per_page
      SolidQueueMonitor.jobs_per_page
    end

    # Preload job statuses to avoid N+1 queries
    def preload_job_statuses(jobs)
      return if jobs.empty?

      # Get all job IDs
      job_ids = jobs.map(&:id)

      # Find all failed jobs in a single query
      failed_job_ids = SolidQueue::FailedExecution.where(job_id: job_ids).pluck(:job_id)

      # Find all scheduled jobs in a single query
      scheduled_job_ids = SolidQueue::ScheduledExecution.where(job_id: job_ids).pluck(:job_id)

      # Attach the status information to each job
      jobs.each do |job|
        job.instance_variable_set(:@failed, failed_job_ids.include?(job.id))
        job.instance_variable_set(:@scheduled, scheduled_job_ids.include?(job.id))
      end

      # Define the method to check if a job is failed
      SolidQueue::Job.class_eval do
        def failed?
          if instance_variable_defined?(:@failed)
            @failed
          else
            SolidQueue::FailedExecution.exists?(job_id: id)
          end
        end

        def scheduled?
          if instance_variable_defined?(:@scheduled)
            @scheduled
          else
            SolidQueue::ScheduledExecution.exists?(job_id: id)
          end
        end
      end
    end

    def filter_jobs(relation)
      relation = relation.where('class_name LIKE ?', "%#{params[:class_name]}%") if params[:class_name].present?
      relation = relation.where('queue_name LIKE ?', "%#{params[:queue_name]}%") if params[:queue_name].present?
      relation = filter_by_arguments(relation) if params[:arguments].present?

      if params[:status].present?
        case params[:status]
        when 'completed'
          relation = relation.where.not(finished_at: nil)
        when 'failed'
          relation = relation.where(id: SolidQueue::FailedExecution.select(:job_id))
        when 'scheduled'
          relation = relation.where(id: SolidQueue::ScheduledExecution.select(:job_id))
        when 'pending'
          relation = relation.where(finished_at: nil)
                             .where.not(id: SolidQueue::FailedExecution.select(:job_id))
                             .where.not(id: SolidQueue::ScheduledExecution.select(:job_id))
        end
      end

      relation
    end

    def filter_by_arguments(relation)
      # Use ILIKE for case-insensitive search in PostgreSQL
      relation.where('arguments::text ILIKE ?', "%#{params[:arguments]}%")
    end

    def filter_ready_jobs(relation)
      return relation unless params[:class_name].present? || params[:queue_name].present? || params[:arguments].present?

      if params[:class_name].present?
        relation = relation.where(job_id: SolidQueue::Job.where('class_name LIKE ?', "%#{params[:class_name]}%").select(:id))
      end

      relation = relation.where('queue_name LIKE ?', "%#{params[:queue_name]}%") if params[:queue_name].present?

      if params[:arguments].present?
        relation = relation.where(job_id: SolidQueue::Job.where('arguments::text ILIKE ?', "%#{params[:arguments]}%").select(:id))
      end

      relation
    end

    def filter_scheduled_jobs(relation)
      return relation unless params[:class_name].present? || params[:queue_name].present? || params[:arguments].present?

      if params[:class_name].present?
        relation = relation.where(job_id: SolidQueue::Job.where('class_name LIKE ?', "%#{params[:class_name]}%").select(:id))
      end

      relation = relation.where('queue_name LIKE ?', "%#{params[:queue_name]}%") if params[:queue_name].present?

      if params[:arguments].present?
        relation = relation.where(job_id: SolidQueue::Job.where('arguments::text ILIKE ?', "%#{params[:arguments]}%").select(:id))
      end

      relation
    end

    def filter_recurring_jobs(relation)
      return relation unless params[:class_name].present? || params[:queue_name].present? || params[:arguments].present?

      relation = relation.where('class_name LIKE ?', "%#{params[:class_name]}%") if params[:class_name].present?
      relation = relation.where('queue_name LIKE ?', "%#{params[:queue_name]}%") if params[:queue_name].present?

      # Add arguments filtering if the model has arguments column
      if params[:arguments].present? && relation.column_names.include?('arguments')
        relation = relation.where('arguments::text ILIKE ?',
                                  "%#{params[:arguments]}%")
      end

      relation
    end

    def filter_failed_jobs(relation)
      return relation unless params[:class_name].present? || params[:queue_name].present? || params[:arguments].present?

      if params[:class_name].present?
        relation = relation.where(job_id: SolidQueue::Job.where('class_name LIKE ?', "%#{params[:class_name]}%").select(:id))
      end

      if params[:queue_name].present?
        relation = if relation.column_names.include?('queue_name')
                     relation.where('queue_name LIKE ?', "%#{params[:queue_name]}%")
                   else
                     relation.where(job_id: SolidQueue::Job.where('queue_name LIKE ?', "%#{params[:queue_name]}%").select(:id))
                   end
      end

      if params[:arguments].present?
        relation = relation.where(job_id: SolidQueue::Job.where('arguments::text ILIKE ?', "%#{params[:arguments]}%").select(:id))
      end

      relation
    end

    def filter_params
      {
        class_name: params[:class_name],
        queue_name: params[:queue_name],
        arguments: params[:arguments],
        status: params[:status]
      }
    end

    def sort_params
      {
        sort_by: params[:sort_by],
        sort_direction: params[:sort_direction]
      }
    end

    def apply_sorting(relation, allowed_columns, default_column, default_direction = :desc)
      column = sort_params[:sort_by]
      direction = sort_params[:sort_direction]
      column = default_column unless allowed_columns.include?(column)
      direction = %w[asc desc].include?(direction) ? direction.to_sym : default_direction
      relation.order(column => direction)
    end

    def apply_execution_sorting(relation, allowed_columns, default_column, default_direction = :desc)
      column = sort_params[:sort_by]
      direction = sort_params[:sort_direction]
      column = default_column unless allowed_columns.include?(column)
      direction = %w[asc desc].include?(direction) ? direction.to_sym : default_direction

      # Columns that exist on the jobs table, not on execution tables
      job_table_columns = %w[class_name queue_name]

      if job_table_columns.include?(column)
        relation.joins(:job).order("solid_queue_jobs.#{column}" => direction)
      else
        relation.order(column => direction)
      end
    end
  end
end
