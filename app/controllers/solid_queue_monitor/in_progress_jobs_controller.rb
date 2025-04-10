# frozen_string_literal: true

module SolidQueueMonitor
  class InProgressJobsController < BaseController
    def index
      base_query = SolidQueue::ClaimedExecution.includes(:job).order(created_at: :desc)
      @in_progress_jobs = paginate(filter_in_progress_jobs(base_query))

      render_page('In Progress Jobs', SolidQueueMonitor::InProgressJobsPresenter.new(@in_progress_jobs[:records],
                                                                                     current_page: @in_progress_jobs[:current_page],
                                                                                     total_pages: @in_progress_jobs[:total_pages],
                                                                                     filters: filter_params).render)
    end

    private

    def filter_in_progress_jobs(relation)
      return relation if params[:class_name].blank? && params[:arguments].blank?

      if params[:class_name].present?
        job_ids = SolidQueue::Job.where('class_name LIKE ?', "%#{params[:class_name]}%").pluck(:id)
        relation = relation.where(job_id: job_ids)
      end

      if params[:arguments].present?
        job_ids = SolidQueue::Job.where('arguments::text ILIKE ?', "%#{params[:arguments]}%").pluck(:id)
        relation = relation.where(job_id: job_ids)
      end

      relation
    end
  end
end
