module SolidQueueMonitor
  class MonitorController < ActionController::Base
    include ActionController::HttpAuthentication::Basic::ControllerMethods

    before_action :authenticate
    layout false
    skip_before_action :verify_authenticity_token, only: [:execute_job]

    def index
      @message = params[:message]
      @message_type = params[:message_type]
      
      @stats = {
        total_jobs: SolidQueue::Job.count,
        scheduled: SolidQueue::ScheduledExecution.count,
        ready: SolidQueue::ReadyExecution.count,
        failed: SolidQueue::FailedExecution.count,
        recurring: SolidQueue::RecurringTask.count
      }

      @recent_jobs = SolidQueue::Job.order(created_at: :desc)
                                  .limit(SolidQueueMonitor.jobs_per_page)
      
      render html: generate_html('Recent Jobs', generate_recent_jobs_table).html_safe
    end

    def scheduled_jobs
      @scheduled_jobs = SolidQueue::ScheduledExecution.includes(:job)
                                                     .order(scheduled_at: :asc)
                                                     .limit(SolidQueueMonitor.jobs_per_page)
      
      render html: generate_html('Scheduled Jobs', generate_scheduled_jobs_table).html_safe
    end

    def recurring_jobs
      @recurring_jobs = SolidQueue::RecurringTask.order(:key)
      
      render html: generate_html('Recurring Jobs', generate_recurring_jobs_table).html_safe
    end

    def failed_jobs
      @failed_jobs = SolidQueue::FailedExecution.includes(:job)
                                               .order(created_at: :desc)
                                               .limit(SolidQueueMonitor.jobs_per_page)
      
      render html: generate_html('Failed Jobs', generate_failed_jobs_table).html_safe
    end

    # ... keep existing execute_job, authenticate, and auth_check methods ...

    private

    def generate_html(title, content)
      <<-HTML
        <!DOCTYPE html>
        <html>
          <head>
            <title>Solid Queue Monitor - #{title}</title>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
              #{generate_css}
            </style>
          </head>
          <body>
            #{render_message}
            <div class="container">
              <header>
                <h1>Solid Queue Monitor</h1>
                <nav class="navigation">
                  <a href="#{root_path}" class="nav-link">Overview</a>
                  <a href="#{scheduled_jobs_path}" class="nav-link">Scheduled Jobs</a>
                  <a href="#{recurring_jobs_path}" class="nav-link">Recurring Jobs</a>
                  <a href="#{failed_jobs_path}" class="nav-link">Failed Jobs</a>
                </nav>
              </header>

              #{show_stats if current_page == root_path}

              <div class="section">
                <h2>#{title}</h2>
                #{content}
              </div>

              <footer>
                <p>Powered by Solid Queue Monitor</p>
              </footer>
            </div>
          </body>
        </html>
      HTML
    end

    def show_stats
      <<-HTML
        <div class="stats">
          #{generate_stats_html}
        </div>
      HTML
    end

    def current_page
      request.path
    end

    # Add navigation styles to your existing CSS
    def generate_css
      <<-CSS
        #{existing_css}

        .navigation {
          margin: 1rem 0;
          display: flex;
          justify-content: center;
          gap: 1rem;
        }

        .nav-link {
          text-decoration: none;
          color: var(--text-color);
          padding: 0.5rem 1rem;
          border-radius: 0.375rem;
          background: white;
          box-shadow: 0 1px 3px rgba(0,0,0,0.1);
          transition: all 0.2s;
        }

        .nav-link:hover {
          background: var(--primary-color);
          color: white;
        }
      CSS
    end

    # ... keep your existing table generation methods ...
  end
end