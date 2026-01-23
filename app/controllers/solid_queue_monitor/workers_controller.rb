# frozen_string_literal: true

module SolidQueueMonitor
  class WorkersController < BaseController
    def index
      base_query = SolidQueue::Process.order(created_at: :desc)
      filtered_query = filter_workers(base_query)
      @processes = paginate(filtered_query)

      render_page('Workers', SolidQueueMonitor::WorkersPresenter.new(
        @processes[:records],
        current_page: @processes[:current_page],
        total_pages: @processes[:total_pages],
        filters: worker_filter_params
      ).render)
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
  end
end
