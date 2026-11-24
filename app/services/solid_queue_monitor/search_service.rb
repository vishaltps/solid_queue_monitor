# frozen_string_literal: true

module SolidQueueMonitor
  class SearchService
    RESULTS_LIMIT = 25

    def initialize(query)
      @query = query
    end

    def search
      return empty_results if @query.blank?

      pattern = Arel::Nodes.build_quoted("%#{ActiveRecord::Base.sanitize_sql_like(@query.to_s)}%")

      {
        ready: search_ready_jobs(pattern),
        scheduled: search_scheduled_jobs(pattern),
        failed: search_failed_jobs(pattern),
        in_progress: search_in_progress_jobs(pattern),
        completed: search_completed_jobs(pattern),
        recurring: search_recurring_tasks(pattern)
      }
    end

    private

    def empty_results
      {
        ready: [],
        scheduled: [],
        failed: [],
        in_progress: [],
        completed: [],
        recurring: []
      }
    end

    def search_ready_jobs(pattern)
      SolidQueue::ReadyExecution
        .joins(:job)
        .where(matching_any(job_columns, pattern))
        .includes(:job)
        .limit(RESULTS_LIMIT)
    end

    def search_scheduled_jobs(pattern)
      SolidQueue::ScheduledExecution
        .joins(:job)
        .where(matching_any(job_columns, pattern))
        .includes(:job)
        .limit(RESULTS_LIMIT)
    end

    def search_failed_jobs(pattern)
      SolidQueue::FailedExecution
        .joins(:job)
        .where(matching_any(job_columns + [SolidQueue::FailedExecution.arel_table[:error]], pattern))
        .includes(:job)
        .limit(RESULTS_LIMIT)
    end

    def search_in_progress_jobs(pattern)
      SolidQueue::ClaimedExecution
        .joins(:job)
        .where(matching_any(job_columns, pattern))
        .includes(:job)
        .limit(RESULTS_LIMIT)
    end

    def search_completed_jobs(pattern)
      SolidQueue::Job
        .where.not(finished_at: nil)
        .where(matching_any(job_columns, pattern))
        .order(finished_at: :desc)
        .limit(RESULTS_LIMIT)
    end

    def search_recurring_tasks(pattern)
      SolidQueue::RecurringTask
        .where(matching_any(recurring_task_columns, pattern))
        .limit(RESULTS_LIMIT)
    end

    def matching_any(columns, pattern)
      columns.map { |column| column.matches(pattern, '\\') }.reduce(:or)
    end

    def job_columns
      jobs = SolidQueue::Job.arel_table
      [jobs[:class_name], jobs[:queue_name], jobs[:arguments], jobs[:active_job_id]]
    end

    def recurring_task_columns
      tasks = SolidQueue::RecurringTask.arel_table
      [tasks[:key], tasks[:class_name]]
    end
  end
end
