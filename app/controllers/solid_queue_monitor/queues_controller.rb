# frozen_string_literal: true

module SolidQueueMonitor
  class QueuesController < BaseController
    SORTABLE_COLUMNS = %w[queue_name job_count].freeze
    QUEUE_DETAILS_SORTABLE_COLUMNS = %w[class_name created_at].freeze

    def index
      base_query = SolidQueue::Job.group(:queue_name)
                                  .select('queue_name, COUNT(*) as job_count')
      @queues = apply_queue_sorting(base_query)
      @paused_queues = QueuePauseService.paused_queues

      render_page('Queues', SolidQueueMonitor::QueuesPresenter.new(@queues, @paused_queues, sort: sort_params).render)
    end

    def show
      @queue_name = params[:queue_name]
      @paused = QueuePauseService.paused_queues.include?(@queue_name)

      # Get all jobs for this queue with filtering and pagination
      base_query = SolidQueue::Job.where(queue_name: @queue_name)
      sorted_query = apply_sorting(filter_queue_jobs(base_query), QUEUE_DETAILS_SORTABLE_COLUMNS, 'created_at', :desc)
      @jobs = paginate(sorted_query)
      preload_job_statuses(@jobs[:records])

      @counts = calculate_queue_counts(@queue_name)

      render_page("Queue: #{@queue_name}",
                  SolidQueueMonitor::QueueDetailsPresenter.new(
                    queue_name: @queue_name,
                    paused: @paused,
                    jobs: @jobs[:records],
                    counts: @counts,
                    current_page: @jobs[:current_page],
                    total_pages: @jobs[:total_pages],
                    filters: queue_filter_params,
                    sort: sort_params
                  ).render)
    end

    def pause
      queue_name = params[:queue_name]
      result = QueuePauseService.new(queue_name).pause

      set_flash_message(result[:message], result[:success] ? 'success' : 'error')
      redirect_to params[:redirect_to] || queues_path
    end

    def resume
      queue_name = params[:queue_name]
      result = QueuePauseService.new(queue_name).resume

      set_flash_message(result[:message], result[:success] ? 'success' : 'error')
      redirect_to params[:redirect_to] || queues_path
    end

    private

    def calculate_queue_counts(queue_name)
      {
        total: SolidQueue::Job.where(queue_name: queue_name).count,
        ready: SolidQueue::ReadyExecution.where(queue_name: queue_name).count,
        scheduled: SolidQueue::ScheduledExecution.where(queue_name: queue_name).count,
        in_progress: SolidQueue::ClaimedExecution.joins(:job).where(solid_queue_jobs: { queue_name: queue_name }).count,
        failed: SolidQueue::FailedExecution.joins(:job).where(solid_queue_jobs: { queue_name: queue_name }).count,
        completed: SolidQueue::Job.where(queue_name: queue_name).where.not(finished_at: nil).count
      }
    end

    def filter_queue_jobs(relation)
      relation = relation.where('class_name LIKE ?', "%#{params[:class_name]}%") if params[:class_name].present?
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
          ready_job_ids = SolidQueue::ReadyExecution.pluck(:job_id)
          relation = relation.where(id: ready_job_ids)
        when 'in_progress'
          claimed_job_ids = SolidQueue::ClaimedExecution.pluck(:job_id)
          relation = relation.where(id: claimed_job_ids)
        end
      end

      relation
    end

    def queue_filter_params
      {
        class_name: params[:class_name],
        arguments: params[:arguments],
        status: params[:status]
      }
    end

    def apply_queue_sorting(relation)
      column = sort_params[:sort_by]
      direction = sort_params[:sort_direction]
      column = 'job_count' unless SORTABLE_COLUMNS.include?(column)
      direction = 'desc' unless %w[asc desc].include?(direction)

      relation.order("#{column} #{direction}")
    end
  end
end
