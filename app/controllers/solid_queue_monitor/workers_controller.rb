# frozen_string_literal: true

module SolidQueueMonitor
  class WorkersController < BaseController
    SORTABLE_COLUMNS = %w[hostname last_heartbeat_at].freeze

    def index
      base_query = SolidQueue::Process.all
      sorted_query = apply_sorting(filter_workers(base_query), SORTABLE_COLUMNS, 'last_heartbeat_at', :desc)
      @processes = paginate(sorted_query)
      @process_records = @processes[:records].to_a
      @filters = worker_filter_params
      @sort = sort_params
      @summary = worker_summary
      preload_claimed_data
    end

    def remove
      process = SolidQueue::Process.find_by(id: params[:id])

      if process
        process.destroy
        set_flash_message('Process removed successfully.', 'success')
      else
        set_flash_message('Process not found.', 'error')
      end

      redirect_to workers_path
    end

    def prune
      dead_threshold = 10.minutes.ago
      dead_processes = SolidQueue::Process.where(last_heartbeat_at: ..dead_threshold)
      count = dead_processes.count

      if count.positive?
        dead_processes.destroy_all
        set_flash_message("Successfully removed #{count} dead process#{'es' if count > 1}.", 'success')
      else
        set_flash_message('No dead processes to remove.', 'success')
      end

      redirect_to workers_path
    end

    private

    def filter_workers(relation)
      relation = relation.where(kind: params[:kind]) if params[:kind].present?
      relation = relation.where('hostname LIKE ?', "%#{params[:hostname]}%") if params[:hostname].present?

      if params[:status].present?
        case params[:status]
        when 'healthy'
          relation = relation.where('last_heartbeat_at > ?', 5.minutes.ago)
        when 'stale'
          relation = relation.where('last_heartbeat_at <= ? AND last_heartbeat_at > ?', 5.minutes.ago, 10.minutes.ago)
        when 'dead'
          relation = relation.where(last_heartbeat_at: ..10.minutes.ago)
        end
      end

      relation
    end

    def worker_filter_params
      {
        kind: params[:kind],
        hostname: params[:hostname],
        status: params[:status]
      }
    end

    def worker_summary
      all_processes = SolidQueue::Process.all.to_a
      {
        total: all_processes.count,
        healthy: all_processes.count { |process| view_context.worker_status(process) == :healthy },
        stale: all_processes.count { |process| view_context.worker_status(process) == :stale },
        dead: all_processes.count { |process| view_context.worker_status(process) == :dead }
      }
    end

    def preload_claimed_data
      process_ids = @process_records.map(&:id)
      @claimed_counts = SolidQueue::ClaimedExecution.where(process_id: process_ids).group(:process_id).count
      @claimed_jobs = SolidQueue::ClaimedExecution.includes(:job).where(process_id: process_ids).each_with_object({}) do |execution, hash|
        hash[execution.process_id] ||= []
        hash[execution.process_id] << execution.job
      end
    end
  end
end
