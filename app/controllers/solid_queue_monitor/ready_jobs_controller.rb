# frozen_string_literal: true

module SolidQueueMonitor
  class ReadyJobsController < BaseController
    SORTABLE_COLUMNS = %w[class_name queue_name priority created_at].freeze

    def index
      base_query = SolidQueue::ReadyExecution.includes(:job)
      sorted_query = apply_execution_sorting(filter_ready_jobs(base_query), SORTABLE_COLUMNS, 'created_at', :desc)
      @ready_jobs = paginate(sorted_query)
      @filters = filter_params
      @sort = sort_params
      @action_path = ready_jobs_path
    end

    def discard
      id = params[:id]

      if SolidQueueMonitor::DiscardReadyJobService.new.call(id)
        set_flash_message("Job #{id} has been discarded.", 'success')
      else
        set_flash_message("Failed to discard job #{id}: it is no longer ready.", 'error')
      end

      redirect_to ready_jobs_path
    rescue StandardError => e
      set_flash_message("Failed to discard job #{id}: #{e.message}", 'error')
      redirect_to ready_jobs_path
    end

    def discard_all
      result = SolidQueueMonitor::DiscardReadyJobService.new.discard_many(params[:job_ids])

      if result[:success]
        set_flash_message(result[:message], 'success')
      else
        set_flash_message(result[:message], 'error')
      end
      redirect_to ready_jobs_path
    end
  end
end
