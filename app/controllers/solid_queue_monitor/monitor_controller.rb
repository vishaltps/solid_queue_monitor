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
      @failed_jobs = SolidQueue::FailedExecution.includes(:job)
                                               .order(created_at: :desc)
                                               .limit(SolidQueueMonitor.jobs_per_page)
      @scheduled_jobs = SolidQueue::ScheduledExecution.includes(:job)
                                                     .order(scheduled_at: :asc)
                                                     .limit(SolidQueueMonitor.jobs_per_page)
      @recurring_jobs = SolidQueue::RecurringTask.order(:key)

      render html: generate_html.html_safe
    end

    def execute_job
      execution = SolidQueue::ScheduledExecution.find_by(id: params[:id])
      
      if execution
        SolidQueue::ReadyExecution.create!(
          job_id: execution.job_id,
          queue_name: execution.queue_name,
          priority: execution.priority
        )
        execution.destroy
        redirect_url = "#{root_path}?message=Job moved to ready queue&message_type=success"
      else
        redirect_url = "#{root_path}?message=Job not found&message_type=error"
      end

      redirect_to redirect_url
    end

    private

    def authenticate
      authenticate_or_request_with_http_basic do |username, password|
        auth_check(username, password)
      end
    end

    def auth_check(username, password)
      username == SolidQueueMonitor.username && 
      password == SolidQueueMonitor.password
    end

    private

    def generate_html
      <<-HTML
        <!DOCTYPE html>
        <html>
          <head>
            <title>Solid Queue Monitor</title>
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
                <p class="subtitle">Queue Status Overview</p>
              </header>

              <div class="stats">
                #{generate_stats_html}
              </div>

              <div class="section">
                <h2>Recent Jobs</h2>
                #{generate_recent_jobs_table}
              </div>

              <div class="section">
                <h2>Scheduled Jobs</h2>
                #{generate_scheduled_jobs_table}
              </div>

              <div class="section">
                <h2>Failed Jobs</h2>
                #{generate_failed_jobs_table}
              </div>

              <div class="section">
                <h2>Recurring Jobs</h2>
                #{generate_recurring_jobs_table}
              </div>

              <footer>
                <p>Powered by Solid Queue Monitor</p>
              </footer>
            </div>
          </body>
        </html>
      HTML
    end

    def generate_css
      <<-CSS
        :root {
          --primary-color: #3b82f6;
          --success-color: #10b981;
          --error-color: #ef4444;
          --text-color: #1f2937;
          --border-color: #e5e7eb;
          --background-color: #f9fafb;
        }

        * { box-sizing: border-box; margin: 0; padding: 0; }

        body {
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
          line-height: 1.5;
          color: var(--text-color);
          background: var(--background-color);
        }

        .container {
          max-width: 1200px;
          margin: 0 auto;
          padding: 2rem;
        }

        header {
          margin-bottom: 2rem;
          text-align: center;
        }

        h1 {
          font-size: 2rem;
          font-weight: 600;
          margin-bottom: 0.5rem;
        }

        .subtitle {
          color: #6b7280;
        }

        .stats {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
          gap: 1rem;
          margin-bottom: 2rem;
        }

        .stat-card {
          background: white;
          padding: 1.5rem;
          border-radius: 0.5rem;
          box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }

        .stat-card h3 {
          color: #6b7280;
          font-size: 0.875rem;
          text-transform: uppercase;
          letter-spacing: 0.05em;
        }

        .stat-card p {
          font-size: 1.5rem;
          font-weight: 600;
          margin-top: 0.5rem;
        }

        .section {
          background: white;
          border-radius: 0.5rem;
          box-shadow: 0 1px 3px rgba(0,0,0,0.1);
          margin-bottom: 2rem;
          overflow: hidden;
        }

        .section h2 {
          padding: 1rem;
          border-bottom: 1px solid var(--border-color);
          font-size: 1.25rem;
        }

        table {
          width: 100%;
          border-collapse: collapse;
        }

        th, td {
          padding: 0.75rem 1rem;
          text-align: left;
          border-bottom: 1px solid var(--border-color);
        }

        th {
          background: var(--background-color);
          font-weight: 500;
          font-size: 0.875rem;
          text-transform: uppercase;
          letter-spacing: 0.05em;
        }

        .status-badge {
          display: inline-block;
          padding: 0.25rem 0.5rem;
          border-radius: 9999px;
          font-size: 0.75rem;
          font-weight: 500;
        }

        .status-completed { background: #d1fae5; color: #065f46; }
        .status-failed { background: #fee2e2; color: #991b1b; }
        .status-scheduled { background: #dbeafe; color: #1e40af; }
        .status-pending { background: #f3f4f6; color: #374151; }

        .execute-btn {
          background: var(--primary-color);
          color: white;
          border: none;
          padding: 0.5rem 1rem;
          border-radius: 0.375rem;
          font-size: 0.875rem;
          cursor: pointer;
          transition: background-color 0.2s;
        }

        .execute-btn:hover {
          background: #2563eb;
        }

        .message {
          padding: 1rem;
          margin-bottom: 1rem;
          border-radius: 0.375rem;
        }

        .message-success {
          background: #d1fae5;
          color: #065f46;
        }

        .message-error {
          background: #fee2e2;
          color: #991b1b;
        }

        footer {
          text-align: center;
          padding: 2rem 0;
          color: #6b7280;
        }

        @media (max-width: 768px) {
          .container { padding: 1rem; }
          .stats { grid-template-columns: 1fr; }
          th, td { padding: 0.5rem; }
        }
      CSS
    end

    def generate_stats_html
      @stats.map { |key, value| 
        "<div class='stat-card'>
          <h3>#{key.to_s.humanize}</h3>
          <p>#{value}</p>
        </div>"
      }.join
    end

    def generate_recent_jobs_table
      <<-HTML
        <table>
          <thead>
            <tr>
              <th>ID</th>
              <th>Job</th>
              <th>Queue</th>
              <th>Status</th>
              <th>Created At</th>
            </tr>
          </thead>
          <tbody>
            #{@recent_jobs.map { |job|
              status = job_status(job)
              "<tr>
                <td>#{job.id}</td>
                <td>#{job.class_name}</td>
                <td>#{job.queue_name}</td>
                <td><span class='status-badge status-#{status}'>#{status}</span></td>
                <td>#{job.created_at&.strftime('%Y-%m-%d %H:%M:%S')}</td>
              </tr>"
            }.join}
          </tbody>
        </table>
      HTML
    end

    def generate_scheduled_jobs_table
      <<-HTML
        <table>
          <thead>
            <tr>
              <th>Job</th>
              <th>Queue</th>
              <th>Scheduled At</th>
              <th>Arguments</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            #{@scheduled_jobs.map { |execution|
              "<tr>
                <td>#{execution.job.class_name}</td>
                <td>#{execution.queue_name}</td>
                <td>#{execution.scheduled_at&.strftime('%Y-%m-%d %H:%M:%S')}</td>
                <td><code>#{execution.job.arguments}</code></td>
                <td>
                  <form action='#{execute_job_path}' method='POST' style='display: inline;'>
                    <input type='hidden' name='id' value='#{execution.id}'>
                    <button type='submit' class='execute-btn'>Execute Now</button>
                  </form>
                </td>
              </tr>"
            }.join}
          </tbody>
        </table>
      HTML
    end

    def generate_failed_jobs_table
      <<-HTML
        <table>
          <thead>
            <tr>
              <th>Job</th>
              <th>Error</th>
              <th>Failed At</th>
              <th>Arguments</th>
            </tr>
          </thead>
          <tbody>
            #{@failed_jobs.map { |execution|
              "<tr>
                <td>#{execution.job.class_name}</td>
                <td style='color: var(--error-color)'>#{execution.error['message']&.truncate(100)}</td>
                <td>#{execution.created_at&.strftime('%Y-%m-%d %H:%M:%S')}</td>
                <td><code>#{execution.job.arguments}</code></td>
              </tr>"
            }.join}
          </tbody>
        </table>
      HTML
    end

    def generate_recurring_jobs_table
      <<-HTML
        <table>
          <thead>
            <tr>
              <th>Key</th>
              <th>Job</th>
              <th>Schedule</th>
              <th>Queue</th>
              <th>Last Run</th>
            </tr>
          </thead>
          <tbody>
            #{@recurring_jobs.map { |task|
              "<tr>
                <td>#{task.key}</td>
                <td>#{task.class_name}</td>
                <td>#{task.schedule}</td>
                <td>#{task.queue_name}</td>
                <td>#{task.updated_at&.strftime('%Y-%m-%d %H:%M:%S')}</td>
              </tr>"
            }.join}
          </tbody>
        </table>
      HTML
    end

    def render_message
      return '' unless @message
      class_name = @message_type == 'success' ? 'message-success' : 'message-error'
      "<div class='message #{class_name}'>#{@message}</div>"
    end

    def job_status(job)
      return 'completed' if job.finished_at.present?
      return 'failed' if SolidQueue::FailedExecution.exists?(job_id: job.id)
      return 'scheduled' if job.scheduled_at&.future?
      'pending'
    end
  end
end