# frozen_string_literal: true

module SolidQueueMonitor
  class SearchService
    RESULTS_LIMIT = 25

    def initialize(query)
      @query = query
    end

    def search
      return empty_results if @query.blank?

      term = "%#{sanitize_query(@query)}%"

      {
        ready: search_ready_jobs(term),
        scheduled: search_scheduled_jobs(term),
        failed: search_failed_jobs(term),
        in_progress: search_in_progress_jobs(term),
        completed: search_completed_jobs(term),
        recurring: search_recurring_tasks(term)
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

    def sanitize_query(query)
      # Escape % to prevent LIKE pattern injection
      # We don't escape _ because it requires database-specific ESCAPE clauses
      query.to_s.gsub('%', '\%')
    end

    def search_ready_jobs(term)
      SolidQueue::ReadyExecution
        .joins(:job)
        .where(job_search_conditions, term: term)
        .includes(:job)
        .limit(RESULTS_LIMIT)
    end

    def search_scheduled_jobs(term)
      SolidQueue::ScheduledExecution
        .joins(:job)
        .where(job_search_conditions, term: term)
        .includes(:job)
        .limit(RESULTS_LIMIT)
    end

    def search_failed_jobs(term)
      SolidQueue::FailedExecution
        .joins(:job)
        .where(failed_job_search_conditions, term: term)
        .includes(:job)
        .limit(RESULTS_LIMIT)
    end

    def search_in_progress_jobs(term)
      SolidQueue::ClaimedExecution
        .joins(:job)
        .where(job_search_conditions, term: term)
        .includes(:job)
        .limit(RESULTS_LIMIT)
    end

    def search_completed_jobs(term)
      SolidQueue::Job
        .where.not(finished_at: nil)
        .where(completed_job_search_conditions, term: term)
        .order(finished_at: :desc)
        .limit(RESULTS_LIMIT)
    end

    def search_recurring_tasks(term)
      SolidQueue::RecurringTask
        .where(recurring_task_search_conditions, term: term)
        .limit(RESULTS_LIMIT)
    end

    def job_search_conditions
      <<~SQL.squish
        solid_queue_jobs.class_name LIKE :term
        OR solid_queue_jobs.queue_name LIKE :term
        OR solid_queue_jobs.arguments LIKE :term
        OR solid_queue_jobs.active_job_id LIKE :term
      SQL
    end

    def failed_job_search_conditions
      <<~SQL.squish
        solid_queue_jobs.class_name LIKE :term
        OR solid_queue_jobs.queue_name LIKE :term
        OR solid_queue_jobs.arguments LIKE :term
        OR solid_queue_jobs.active_job_id LIKE :term
        OR solid_queue_failed_executions.error LIKE :term
      SQL
    end

    def completed_job_search_conditions
      <<~SQL.squish
        class_name LIKE :term
        OR queue_name LIKE :term
        OR arguments LIKE :term
        OR active_job_id LIKE :term
      SQL
    end

    def recurring_task_search_conditions
      <<~SQL.squish
        solid_queue_recurring_tasks.key LIKE :term
        OR solid_queue_recurring_tasks.class_name LIKE :term
      SQL
    end
  end
end
