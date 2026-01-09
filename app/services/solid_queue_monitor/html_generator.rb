# frozen_string_literal: true

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
        #{generate_auto_refresh_script}
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
          <div class="header-top">
            <h1>Solid Queue Monitor</h1>
            #{generate_auto_refresh_controls}
          </div>
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

    def generate_auto_refresh_controls
      return '' unless SolidQueueMonitor.auto_refresh_enabled

      interval = SolidQueueMonitor.auto_refresh_interval
      <<-HTML
        <div class="auto-refresh-container" title="Auto-refresh every #{interval}s" data-tooltip="Auto-refresh: Dashboard updates automatically every #{interval} seconds. Toggle to enable/disable.">
          <span class="auto-refresh-indicator" id="auto-refresh-indicator"></span>
          <span class="auto-refresh-countdown" id="auto-refresh-countdown">#{interval}s</span>
          <label class="auto-refresh-switch" title="Toggle auto-refresh">
            <input type="checkbox" id="auto-refresh-toggle" checked>
            <span class="switch-slider"></span>
          </label>
          <button class="refresh-now-btn" id="refresh-now-btn" title="Refresh now">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M21 2v6h-6M3 12a9 9 0 0 1 15-6.7L21 8M3 22v-6h6M21 12a9 9 0 0 1-15 6.7L3 16"/>
            </svg>
          </button>
        </div>
      HTML
    end

    def generate_auto_refresh_script
      return '' unless SolidQueueMonitor.auto_refresh_enabled

      "<script>#{auto_refresh_javascript}</script>"
    end

    def auto_refresh_javascript
      interval = SolidQueueMonitor.auto_refresh_interval
      <<-JS
        (function() {
          var REFRESH_INTERVAL = #{interval};
          var countdown = REFRESH_INTERVAL;
          var timerId = null;
          var isEnabled = localStorage.getItem('sqm_auto_refresh') !== 'false';
          #{auto_refresh_dom_elements}
          #{auto_refresh_functions}
          #{auto_refresh_event_listeners}
          #{auto_refresh_init}
        })();
      JS
    end

    def auto_refresh_dom_elements
      <<-JS
        var toggle = document.getElementById('auto-refresh-toggle');
        var indicator = document.getElementById('auto-refresh-indicator');
        var countdownEl = document.getElementById('auto-refresh-countdown');
        var refreshBtn = document.getElementById('refresh-now-btn');
      JS
    end

    def auto_refresh_functions
      <<-JS
        function updateUI() {
          if (toggle) toggle.checked = isEnabled;
          if (indicator) indicator.classList.toggle('active', isEnabled);
          if (countdownEl) {
            countdownEl.textContent = countdown + 's';
            countdownEl.style.opacity = isEnabled ? '1' : '0.4';
          }
        }
        function tick() {
          countdown--;
          if (countdown <= 0) { refresh(); } else { updateUI(); }
        }
        function startTimer() {
          stopTimer();
          countdown = REFRESH_INTERVAL;
          updateUI();
          timerId = setInterval(tick, 1000);
        }
        function stopTimer() {
          if (timerId) { clearInterval(timerId); timerId = null; }
        }
        function refresh() { window.location.reload(); }
        function setEnabled(enabled) {
          isEnabled = enabled;
          localStorage.setItem('sqm_auto_refresh', enabled ? 'true' : 'false');
          if (enabled) { startTimer(); } else { stopTimer(); countdown = REFRESH_INTERVAL; updateUI(); }
        }
      JS
    end

    def auto_refresh_event_listeners
      <<-JS
        if (toggle) { toggle.addEventListener('change', function() { setEnabled(this.checked); }); }
        if (refreshBtn) { refreshBtn.addEventListener('click', function() { refresh(); }); }
      JS
    end

    def auto_refresh_init
      <<-JS
        updateUI();
        if (isEnabled) { startTimer(); }
      JS
    end

    def default_url_options
      { only_path: true }
    end
  end
end
