module SolidQueueMonitor
  class HtmlGenerator
    include Rails.application.routes.url_helpers
    include SolidQueueMonitor::Engine.routes.url_helpers

    def initialize(title:, content:, message: nil, message_type: nil)
      @title = title
      @content = content
      @message = message
      @message_type = message_type
    end

    def generate
      <<-HTML
        <!DOCTYPE html>
        <html>
          <head>
            <title>Solid Queue Monitor - #{@title}</title>
            #{generate_head}
          </head>
          <body class="solid_queue_monitor">
            #{generate_body}
          </body>
        </html>
      HTML
    end

    private

    def generate_head
      <<-HTML
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          #{SolidQueueMonitor::StylesheetGenerator.new.generate}
        </style>
      HTML
    end

    def generate_body
      <<-HTML
        #{render_message}
        <div class="container">
          #{generate_header}
          <div class="section">
            <h2>#{@title}</h2>
            #{@content}
          </div>
          #{generate_footer}
        </div>
      HTML
    end
    
    def render_message
      return '' unless @message
      class_name = @message_type == 'success' ? 'message-success' : 'message-error'
      <<-HTML
        <div id="flash-message" class="message #{class_name}">#{@message}</div>
        <script>
          // Automatically hide the flash message after 5 seconds
          document.addEventListener('DOMContentLoaded', function() {
            var flashMessage = document.getElementById('flash-message');
            if (flashMessage) {
              setTimeout(function() {
                flashMessage.style.opacity = '1';
                // Fade out animation
                var fadeEffect = setInterval(function() {
                  if (!flashMessage.style.opacity) {
                    flashMessage.style.opacity = 1;
                  }
                  if (flashMessage.style.opacity > 0) {
                    flashMessage.style.opacity -= 0.1;
                  } else {
                    clearInterval(fadeEffect);
                    flashMessage.style.display = 'none';
                  }
                }, 50);
              }, 5000); // 5 seconds
            }
          });
        </script>
      HTML
    end

    def generate_header
      <<-HTML
        <header>
          <h1>Solid Queue Monitor</h1>
          <nav class="navigation">
            <a href="#{root_path}" class="nav-link">Overview</a>
            <a href="#{ready_jobs_path}" class="nav-link">Ready Jobs</a>
            <a href="#{in_progress_jobs_path}" class="nav-link">In Progress Jobs</a>
            <a href="#{scheduled_jobs_path}" class="nav-link">Scheduled Jobs</a>
            <a href="#{recurring_jobs_path}" class="nav-link">Recurring Jobs</a>
            <a href="#{failed_jobs_path}" class="nav-link">Failed Jobs</a>
            <a href="#{queues_path}" class="nav-link">Queues</a>
          </nav>
        </header>
      HTML
    end

    def generate_footer
      <<-HTML
        <footer>
          <p>Powered by Solid Queue Monitor</p>
        </footer>
      HTML
    end

    def default_url_options
      { only_path: true }
    end
  end
end