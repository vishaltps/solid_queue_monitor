module SolidQueueMonitor
  class MonitorController < ActionController::Base
    include ActionController::HttpAuthentication::Basic::ControllerMethods

    before_action :authenticate
    layout false
    skip_before_action :verify_authenticity_token, only: [:execute_jobs]

    def index
      @stats = SolidQueueMonitor::StatsCalculator.calculate
      @recent_jobs = paginate(SolidQueue::Job.order(created_at: :desc))
      
      render_page('Overview', generate_overview_content)
    end

    def ready_jobs
      @ready_jobs = paginate(SolidQueue::ReadyExecution.includes(:job).order(created_at: :desc))
      render_page('Ready Jobs', SolidQueueMonitor::ReadyJobsPresenter.new(@ready_jobs[:records], 
        current_page: @ready_jobs[:current_page],
        total_pages: @ready_jobs[:total_pages]).render)
    end

    def scheduled_jobs
      @scheduled_jobs = paginate(SolidQueue::ScheduledExecution.includes(:job).order(scheduled_at: :asc))
      render_page('Scheduled Jobs', SolidQueueMonitor::ScheduledJobsPresenter.new(@scheduled_jobs[:records],
        current_page: @scheduled_jobs[:current_page],
        total_pages: @scheduled_jobs[:total_pages]).render)
    end

    def failed_jobs
      @failed_jobs = paginate(SolidQueue::FailedExecution.includes(:job).order(created_at: :desc))
      render_page('Failed Jobs', SolidQueueMonitor::FailedJobsPresenter.new(@failed_jobs[:records],
        current_page: @failed_jobs[:current_page],
        total_pages: @failed_jobs[:total_pages]).render)
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
      SolidQueueMonitor::JobsPresenter.new(@recent_jobs[:records], current_page: @recent_jobs[:current_page],
      total_pages: @recent_jobs[:total_pages]).render
    end

    def current_page
      (params[:page] || 1).to_i
    end

    def per_page
      SolidQueueMonitor.jobs_per_page
    end
  end
end