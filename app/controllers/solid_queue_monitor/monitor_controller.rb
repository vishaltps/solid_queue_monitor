module SolidQueueMonitor
  class MonitorController < ActionController::Base
    include ActionController::HttpAuthentication::Basic::ControllerMethods

    before_action :authenticate
    layout false
    skip_before_action :verify_authenticity_token, only: [:execute_jobs]

    def index
      @stats = SolidQueueMonitor::StatsCalculator.calculate
      @recent_jobs = paginate(filter_jobs(SolidQueue::Job.order(created_at: :desc)))
      
      render_page('Overview', generate_overview_content)
    end

    def ready_jobs
      base_query = SolidQueue::ReadyExecution.includes(:job).order(created_at: :desc)
      @ready_jobs = paginate(filter_ready_jobs(base_query))
      render_page('Ready Jobs', SolidQueueMonitor::ReadyJobsPresenter.new(@ready_jobs[:records], 
        current_page: @ready_jobs[:current_page],
        total_pages: @ready_jobs[:total_pages],
        filters: filter_params
      ).render)
    end

    def scheduled_jobs
      base_query = SolidQueue::ScheduledExecution.includes(:job).order(scheduled_at: :asc)
      @scheduled_jobs = paginate(filter_scheduled_jobs(base_query))
      render_page('Scheduled Jobs', SolidQueueMonitor::ScheduledJobsPresenter.new(@scheduled_jobs[:records],
        current_page: @scheduled_jobs[:current_page],
        total_pages: @scheduled_jobs[:total_pages],
        filters: filter_params
      ).render)
    end

    def failed_jobs
      base_query = SolidQueue::FailedExecution.includes(:job).order(created_at: :desc)
      @failed_jobs = paginate(filter_failed_jobs(base_query))
      render_page('Failed Jobs', SolidQueueMonitor::FailedJobsPresenter.new(@failed_jobs[:records],
        current_page: @failed_jobs[:current_page],
        total_pages: @failed_jobs[:total_pages],
        filters: filter_params
      ).render)
    end

    def queues
      @queues = SolidQueue::Job.group(:queue_name)
                              .select('queue_name, COUNT(*) as job_count')
                              .order('job_count DESC')
      render_page('Queues', SolidQueueMonitor::QueuesPresenter.new(@queues).render)
    end

    def execute_jobs
      if params[:job_ids].present?
        SolidQueueMonitor::ExecuteJobService.new.execute_many(params[:job_ids])
        redirect_url = "#{root_path}?message=Selected jobs moved to ready queue&message_type=success"
      else
        redirect_url = "#{root_path}?message=No jobs selected&message_type=error"
      end
      redirect_to redirect_url
    end

    private

    def authenticate
      authenticate_or_request_with_http_basic do |username, password|
        SolidQueueMonitor::AuthenticationService.authenticate(username, password)
      end
    end

    def paginate(relation)
      PaginationService.new(relation, current_page, per_page).paginate
    end

    def render_page(title, content)
      html = SolidQueueMonitor::HtmlGenerator.new(
        title: title,
        content: content,
        message: params[:notice] || params[:alert],
        message_type: params[:notice] ? 'success' : 'error'
      ).generate
      
      render html: html.html_safe
    end

    def generate_overview_content
      SolidQueueMonitor::StatsPresenter.new(@stats).render + 
      SolidQueueMonitor::JobsPresenter.new(@recent_jobs[:records], 
        current_page: @recent_jobs[:current_page],
        total_pages: @recent_jobs[:total_pages],
        filters: filter_params
      ).render
    end

    def current_page
      (params[:page] || 1).to_i
    end

    def per_page
      SolidQueueMonitor.jobs_per_page
    end

    def filter_jobs(relation)
      relation = relation.where("class_name LIKE ?", "%#{params[:class_name]}%") if params[:class_name].present?
      relation = relation.where("queue_name LIKE ?", "%#{params[:queue_name]}%") if params[:queue_name].present?
      
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

    def filter_ready_jobs(relation)
      return relation unless params[:class_name].present? || params[:queue_name].present?
      
      if params[:class_name].present?
        job_ids = SolidQueue::Job.where("class_name LIKE ?", "%#{params[:class_name]}%").pluck(:id)
        relation = relation.where(job_id: job_ids)
      end
      
      if params[:queue_name].present?
        relation = relation.where("queue_name LIKE ?", "%#{params[:queue_name]}%")
      end
      
      relation
    end

    def filter_scheduled_jobs(relation)
      return relation unless params[:class_name].present? || params[:queue_name].present?
      
      if params[:class_name].present?
        job_ids = SolidQueue::Job.where("class_name LIKE ?", "%#{params[:class_name]}%").pluck(:id)
        relation = relation.where(job_id: job_ids)
      end
      
      if params[:queue_name].present?
        relation = relation.where("queue_name LIKE ?", "%#{params[:queue_name]}%")
      end
      
      relation
    end

    def filter_failed_jobs(relation)
      return relation unless params[:class_name].present? || params[:queue_name].present?
      
      if params[:class_name].present?
        job_ids = SolidQueue::Job.where("class_name LIKE ?", "%#{params[:class_name]}%").pluck(:id)
        relation = relation.where(job_id: job_ids)
      end
      
      if params[:queue_name].present?
        relation = relation.where("queue_name LIKE ?", "%#{params[:queue_name]}%")
      end
      
      relation
    end

    def filter_params
      {
        class_name: params[:class_name],
        queue_name: params[:queue_name],
        status: params[:status]
      }
    end
  end
end