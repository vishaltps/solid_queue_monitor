# frozen_string_literal: true

module SolidQueueMonitor
  class BaseController < SolidQueueMonitor::ApplicationController
    def paginate(relation)
      PaginationService.new(relation, current_page, per_page).paginate
    end

    def render_page(title, content)
      # Get flash message from session
      message = session[:flash_message]
      message_type = session[:flash_type]

      # Clear the flash message from session after using it
      session.delete(:flash_message)
      session.delete(:flash_type)

      html = SolidQueueMonitor::HtmlGenerator.new(
        title: title,
        content: content,
        message: message,
        message_type: message_type
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
          failed_job_ids = SolidQueue::FailedExecution.pluck(:job_id)
          relation = relation.where(id: failed_job_ids)
        when 'scheduled'
          scheduled_job_ids = SolidQueue::ScheduledExecution.pluck(:job_id)
          relation = relation.where(id: scheduled_job_ids)
        when 'pending'
          # Pending jobs are those that are not completed, failed, or scheduled
          failed_job_ids = SolidQueue::FailedExecution.pluck(:job_id)
          scheduled_job_ids = SolidQueue::ScheduledExecution.pluck(:job_id)
          relation = relation.where(finished_at: nil)
                             .where.not(id: failed_job_ids + scheduled_job_ids)
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
        job_ids = SolidQueue::Job.where('class_name LIKE ?', "%#{params[:class_name]}%").pluck(:id)
        relation = relation.where(job_id: job_ids)
      end

      relation = relation.where('queue_name LIKE ?', "%#{params[:queue_name]}%") if params[:queue_name].present?

      # Add arguments filtering
      if params[:arguments].present?
        job_ids = SolidQueue::Job.where('arguments::text ILIKE ?', "%#{params[:arguments]}%").pluck(:id)
        relation = relation.where(job_id: job_ids)
      end

      relation
    end

    def filter_scheduled_jobs(relation)
      return relation unless params[:class_name].present? || params[:queue_name].present? || params[:arguments].present?

      if params[:class_name].present?
        job_ids = SolidQueue::Job.where('class_name LIKE ?', "%#{params[:class_name]}%").pluck(:id)
        relation = relation.where(job_id: job_ids)
      end

      relation = relation.where('queue_name LIKE ?', "%#{params[:queue_name]}%") if params[:queue_name].present?

      # Add arguments filtering
      if params[:arguments].present?
        job_ids = SolidQueue::Job.where('arguments::text ILIKE ?', "%#{params[:arguments]}%").pluck(:id)
        relation = relation.where(job_id: job_ids)
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
        job_ids = SolidQueue::Job.where('class_name LIKE ?', "%#{params[:class_name]}%").pluck(:id)
        relation = relation.where(job_id: job_ids)
      end

      if params[:queue_name].present?
        # Check if FailedExecution has queue_name column
        if relation.column_names.include?('queue_name')
          relation = relation.where('queue_name LIKE ?', "%#{params[:queue_name]}%")
        else
          # If not, filter by job's queue_name
          job_ids = SolidQueue::Job.where('queue_name LIKE ?', "%#{params[:queue_name]}%").pluck(:id)
          relation = relation.where(job_id: job_ids)
        end
      end

      # Add arguments filtering
      if params[:arguments].present?
        job_ids = SolidQueue::Job.where('arguments::text ILIKE ?', "%#{params[:arguments]}%").pluck(:id)
        relation = relation.where(job_id: job_ids)
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
  end
end
