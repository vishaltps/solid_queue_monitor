module SolidQueueMonitor
  class MonitorController < ActionController::Base
    include ActionController::HttpAuthentication::Basic::ControllerMethods
    include ActionController::Flash

    before_action :authenticate, if: -> { SolidQueueMonitor::AuthenticationService.authentication_required? }
    layout false
    skip_before_action :verify_authenticity_token, only: [:execute_jobs, :retry_failed_job, :discard_failed_job, :retry_failed_jobs, :discard_failed_jobs]

    # Define a helper method for setting flash messages
    def set_flash_message(message, type)
      session[:flash_message] = message
      session[:flash_type] = type
    end

    def index
      @stats = SolidQueueMonitor::StatsCalculator.calculate
      
      # Get all jobs with pagination
      @recent_jobs = paginate(filter_jobs(SolidQueue::Job.order(created_at: :desc)))
      
      # Preload failed job information
      preload_job_statuses(@recent_jobs[:records])
      
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

    def recurring_jobs
      base_query = filter_recurring_jobs(SolidQueue::RecurringTask.order(:key))
      @recurring_jobs = paginate(base_query)
      render_page('Recurring Jobs', SolidQueueMonitor::RecurringJobsPresenter.new(@recurring_jobs[:records],
        current_page: @recurring_jobs[:current_page],
        total_pages: @recurring_jobs[:total_pages],
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
        set_flash_message('Selected jobs moved to ready queue', 'success')
      else
        set_flash_message('No jobs selected', 'error')
      end
      redirect_to scheduled_jobs_path
    end

    def retry_failed_job
      id = params[:id]
      service = SolidQueueMonitor::FailedJobService.new
      
      if service.retry_job(id)
        set_flash_message("Job #{id} has been queued for retry.", 'success')
      else
        set_flash_message("Failed to retry job #{id}.", 'error')
      end
      redirect_to failed_jobs_path
    end
    
    def discard_failed_job
      id = params[:id]
      service = SolidQueueMonitor::FailedJobService.new
      
      if service.discard_job(id)
        set_flash_message("Job #{id} has been discarded.", 'success')
      else
        set_flash_message("Failed to discard job #{id}.", 'error')
      end
      redirect_to failed_jobs_path
    end
    
    def retry_failed_jobs
      result = SolidQueueMonitor::FailedJobService.new.retry_all(params[:job_ids])
      
      if result[:success]
        set_flash_message(result[:message], 'success')
      else
        set_flash_message(result[:message], 'error')
      end
      redirect_to failed_jobs_path
    end
    
    def discard_failed_jobs
      result = SolidQueueMonitor::FailedJobService.new.discard_all(params[:job_ids])
      
      if result[:success]
        set_flash_message(result[:message], 'success')
      else
        set_flash_message(result[:message], 'error')
      end
      redirect_to failed_jobs_path
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
      # Get flash message from session
      message = session[:flash_message]
      message_type = session[:flash_type]
      
      # Clear the flash message from session after using it
      session.delete(:flash_message)
      session.delete(:flash_type)
      
      html = SolidQueueMonitor::HtmlGenerator.new(
        title: title,
        content: content,
        message: message,
        message_type: message_type
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

    # Preload job statuses to avoid N+1 queries
    def preload_job_statuses(jobs)
      return if jobs.empty?
      
      # Get all job IDs
      job_ids = jobs.map(&:id)
      
      # Find all failed jobs in a single query
      failed_job_ids = SolidQueue::FailedExecution.where(job_id: job_ids).pluck(:job_id)
      
      # Find all scheduled jobs in a single query
      scheduled_job_ids = SolidQueue::ScheduledExecution.where(job_id: job_ids).pluck(:job_id)
      
      # Attach the status information to each job
      jobs.each do |job|
        job.instance_variable_set(:@failed, failed_job_ids.include?(job.id))
        job.instance_variable_set(:@scheduled, scheduled_job_ids.include?(job.id))
      end
      
      # Define the method to check if a job is failed
      SolidQueue::Job.class_eval do
        def failed?
          if instance_variable_defined?(:@failed)
            @failed
          else
            SolidQueue::FailedExecution.exists?(job_id: id)
          end
        end
        
        def scheduled?
          if instance_variable_defined?(:@scheduled)
            @scheduled
          else
            SolidQueue::ScheduledExecution.exists?(job_id: id)
          end
        end
      end
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

    def filter_recurring_jobs(relation)
      return relation unless params[:class_name].present? || params[:queue_name].present?
      
      if params[:class_name].present?
        relation = relation.where("class_name LIKE ?", "%#{params[:class_name]}%")
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
        # Check if FailedExecution has queue_name column
        if relation.column_names.include?('queue_name')
          relation = relation.where("queue_name LIKE ?", "%#{params[:queue_name]}%")
        else
          # If not, filter by job's queue_name
          job_ids = SolidQueue::Job.where("queue_name LIKE ?", "%#{params[:queue_name]}%").pluck(:id)
          relation = relation.where(job_id: job_ids)
        end
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