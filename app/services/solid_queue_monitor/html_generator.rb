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
        #{generate_chart_script}
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
      nav_items = [
        { path: root_path, label: 'Overview', match: 'Overview' },
        { path: ready_jobs_path, label: 'Ready Jobs', match: 'Ready Jobs' },
        { path: in_progress_jobs_path, label: 'In Progress Jobs', match: 'In Progress' },
        { path: scheduled_jobs_path, label: 'Scheduled Jobs', match: 'Scheduled Jobs' },
        { path: recurring_jobs_path, label: 'Recurring Jobs', match: 'Recurring Jobs' },
        { path: failed_jobs_path, label: 'Failed Jobs', match: 'Failed Jobs' },
        { path: queues_path, label: 'Queues', match: 'Queues' }
      ]

      nav_links = nav_items.map do |item|
        active_class = @title&.include?(item[:match]) ? 'active' : ''
        "<a href=\"#{item[:path]}\" class=\"nav-link #{active_class}\">#{item[:label]}</a>"
      end.join("\n            ")

      <<-HTML
        <header>
          <div class="header-top">
            <h1>Solid Queue Monitor</h1>
            <div class="header-controls">
              #{generate_auto_refresh_controls}
              #{generate_theme_toggle}
            </div>
          </div>
          <nav class="navigation">
            #{nav_links}
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

    def generate_theme_toggle
      <<-HTML
        <button class="theme-toggle-btn" id="theme-toggle-btn" title="Toggle dark mode">
          <svg class="theme-icon-sun" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <circle cx="12" cy="12" r="5"></circle>
            <line x1="12" y1="1" x2="12" y2="3"></line>
            <line x1="12" y1="21" x2="12" y2="23"></line>
            <line x1="4.22" y1="4.22" x2="5.64" y2="5.64"></line>
            <line x1="18.36" y1="18.36" x2="19.78" y2="19.78"></line>
            <line x1="1" y1="12" x2="3" y2="12"></line>
            <line x1="21" y1="12" x2="23" y2="12"></line>
            <line x1="4.22" y1="19.78" x2="5.64" y2="18.36"></line>
            <line x1="18.36" y1="5.64" x2="19.78" y2="4.22"></line>
          </svg>
          <svg class="theme-icon-moon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"></path>
          </svg>
        </button>
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

    def generate_chart_script
      <<-HTML
        <script>
          #{theme_toggle_javascript}
          #{chart_tooltip_javascript}
        </script>
      HTML
    end

    def theme_toggle_javascript
      <<-JS
        (function() {
          var body = document.body;
          var themeBtn = document.getElementById('theme-toggle-btn');
          var storageKey = 'sqm_dark_theme';

          // Check for saved preference or system preference
          function getPreferredTheme() {
            var saved = localStorage.getItem(storageKey);
            if (saved !== null) {
              return saved === 'true';
            }
            // Check system preference
            return window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
          }

          function setTheme(isDark) {
            if (isDark) {
              body.classList.add('dark-theme');
            } else {
              body.classList.remove('dark-theme');
            }
            localStorage.setItem(storageKey, isDark ? 'true' : 'false');
          }

          // Initialize theme
          setTheme(getPreferredTheme());

          // Toggle on button click
          if (themeBtn) {
            themeBtn.addEventListener('click', function() {
              var isDark = body.classList.contains('dark-theme');
              setTheme(!isDark);
            });
          }

          // Listen for system preference changes
          if (window.matchMedia) {
            window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', function(e) {
              // Only auto-switch if user hasn't manually set a preference
              if (localStorage.getItem(storageKey) === null) {
                setTheme(e.matches);
              }
            });
          }
        })();
      JS
    end

    def chart_tooltip_javascript
      <<-JS
        (function() {
          // Chart collapse/expand functionality
          var chartSection = document.getElementById('chart-section');
          var toggleBtn = document.getElementById('chart-toggle-btn');

          if (chartSection && toggleBtn) {
            var isCollapsed = localStorage.getItem('sqm_chart_collapsed') === 'true';

            if (isCollapsed) {
              chartSection.classList.add('collapsed');
            }

            toggleBtn.addEventListener('click', function() {
              chartSection.classList.toggle('collapsed');
              var collapsed = chartSection.classList.contains('collapsed');
              localStorage.setItem('sqm_chart_collapsed', collapsed ? 'true' : 'false');
            });
          }

          // Chart tooltip functionality
          var tooltip = document.getElementById('chart-tooltip');
          if (!tooltip) return;

          var dataPoints = document.querySelectorAll('.data-point');
          var seriesNames = { created: 'Created', completed: 'Completed', failed: 'Failed' };

          dataPoints.forEach(function(point) {
            point.addEventListener('mouseenter', function(e) {
              var series = this.getAttribute('data-series');
              var label = this.getAttribute('data-label');
              var value = this.getAttribute('data-value');

              tooltip.querySelector('.tooltip-label').textContent = label;
              tooltip.querySelector('.tooltip-value').textContent = seriesNames[series] + ': ' + value;
              tooltip.style.display = 'block';
              positionTooltip(e);
            });

            point.addEventListener('mousemove', function(e) {
              positionTooltip(e);
            });

            point.addEventListener('mouseleave', function() {
              tooltip.style.display = 'none';
            });
          });

          function positionTooltip(e) {
            var x = e.clientX + 10;
            var y = e.clientY - 30;

            if (x + tooltip.offsetWidth > window.innerWidth) {
              x = e.clientX - tooltip.offsetWidth - 10;
            }
            if (y < 0) {
              y = e.clientY + 10;
            }

            tooltip.style.left = x + 'px';
            tooltip.style.top = y + 'px';
          }
        })();
      JS
    end

    def default_url_options
      { only_path: true }
    end
  end
end
