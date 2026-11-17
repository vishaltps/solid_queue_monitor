# frozen_string_literal: true

module SolidQueueMonitor
  class DiscardReadyJobService
    def call(id)
      discard_job(id)
    end

    def discard_many(ids)
      return { success: false, message: 'No jobs selected' } if ids.blank?

      success_count = 0
      failed_count = 0

      Array(ids).each do |id|
        if discard_job(id)
          success_count += 1
        else
          failed_count += 1
        end
      rescue StandardError
        failed_count += 1
      end

      if success_count.positive? && failed_count.zero?
        { success: true, message: 'All selected jobs have been discarded' }
      elsif success_count.positive? && failed_count.positive?
        { success: true, message: "#{success_count} jobs discarded, #{failed_count} failed" }
      else
        { success: false, message: 'Failed to discard jobs' }
      end
    end

    private

    # Deleting the ready execution is what claims the job, as it is for a
    # worker: whoever deletes the row first wins. This holds on SQLite too,
    # where the row lock is a no-op, so a job a worker already claimed counts
    # as failed instead of being marked finished while it runs.
    def discard_job(id)
      SolidQueue::ReadyExecution.transaction do
        execution = SolidQueue::ReadyExecution.lock.find_by(id: id)
        next false unless execution
        next false unless SolidQueue::ReadyExecution.where(id: execution.id).delete_all == 1

        # An execution whose job row is gone is just removed.
        job = SolidQueue::Job.find_by(id: execution.job_id)
        next true unless job

        release_concurrency_slot(job)
        job.update!(finished_at: Time.current)
        true
      end
    end

    # A ready job holds its concurrency slot; give it back so blocked jobs
    # with the same key can run. `try` because Solid Queue versions without
    # concurrency controls lack these methods.
    def release_concurrency_slot(job)
      return unless job.try(:concurrency_limited?)

      if job.class_name.safe_constantize
        job.unblock_next_blocked_job
      else
        # The limit comes from the job class, so without it the next blocked
        # job can't be released here. Free the slot by key, as Solid Queue's
        # own bulk discard does; its dispatcher then unblocks waiting jobs.
        SolidQueue::Job.release_all_concurrency_locks([job])
      end
    end
  end
end
