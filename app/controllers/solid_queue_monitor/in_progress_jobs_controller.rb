# frozen_string_literal: true

module SolidQueueMonitor
  class InProgressJobsController < BaseController
    SORTABLE_COLUMNS = %w[class_name queue_name created_at].freeze

    def index
      base_query = SolidQueue::ClaimedExecution.includes(:job)
      sorted_query = apply_execution_sorting(filter_in_progress_jobs(base_query), SORTABLE_COLUMNS, 'created_at', :desc)
      @in_progress_jobs = paginate(sorted_query)

      render_page('In Progress Jobs', SolidQueueMonitor::InProgressJobsPresenter.new(@in_progress_jobs[:records],
                                                                                     current_page: @in_progress_jobs[:current_page],
                                                                                     total_pages: @in_progress_jobs[:total_pages],
                                                                                     filters: filter_params,
                                                                                     sort: sort_params).render)
    end

    private

    def filter_in_progress_jobs(relation)
      return relation if params[:class_name].blank? && params[:arguments].blank?

      if params[:class_name].present?
        relation = relation.where(job_id: SolidQueue::Job.where('class_name LIKE ?', "%#{params[:class_name]}%").select(:id))
      end

      if params[:arguments].present?
        relation = relation.where(job_id: SolidQueue::Job.where('arguments::text ILIKE ?', "%#{params[:arguments]}%").select(:id))
      end

      relation
    end
  end
end
