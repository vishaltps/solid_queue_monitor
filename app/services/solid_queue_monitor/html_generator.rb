# frozen_string_literal: true

module SolidQueueMonitor
  class HtmlGenerator
    include Rails.application.routes.url_helpers
    include SolidQueueMonitor::Engine.routes.url_helpers

    def initialize(title:, content:, message: nil, message_type: nil, search_query: nil, nonce: nil)
      @title = title
      @content = content
      @message = message
      @message_type = message_type
      @search_query = search_query
      @nonce = nonce
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
        #{style_tag_open}
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
        #{script_tag_open}
          document.addEventListener('DOMContentLoaded', function() {
            var el = document.getElementById('flash-message');
            if (!el) return;
            setTimeout(function() {
              el.classList.add('is-fading');
              setTimeout(function() { el.classList.add('is-hidden'); }, 500);
            }, 5000);
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
        { path: queues_path, label: 'Queues', match: 'Queues' },
        { path: workers_path, label: 'Workers', match: 'Workers' }
      ]

      nav_links = nav_items.map do |item|
        active_class = @title&.include?(item[:match]) ? 'active' : ''
        "<a href=\"#{item[:path]}\" class=\"nav-link #{active_class}\">#{item[:label]}</a>"
      end.join("\n            ")

      <<-HTML
        <header>
          <div class="header-top">
            <h1><a href="#{root_path}" class="header-title-link">Solid Queue Monitor</a></h1>
            #{generate_search_box}
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

    def generate_search_box
      search_value = @search_query ? escape_html(@search_query) : ''
      <<-HTML
        <form method="get" action="#{search_path}" class="header-search-form">
          <input type="text" name="q" value="#{search_value}" placeholder="Search by class, queue, job ID, or error..." class="header-search-input">
          <button type="submit" class="header-search-button" title="Search">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <circle cx="11" cy="11" r="8"></circle>
              <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
            </svg>
          </button>
        </form>
      HTML
    end

    def escape_html(text)
      text.to_s.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;').gsub('"', '&quot;')
    end

    def style_tag_open
      @nonce ? %(<style nonce="#{@nonce}">) : '<style>'
    end

    def script_tag_open
      @nonce ? %(<script nonce="#{@nonce}">) : '<script>'
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

      "#{script_tag_open}#{auto_refresh_javascript}</script>"
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
            countdownEl.classList.toggle('countdown-paused', !isEnabled);
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
        #{script_tag_open}
          #{theme_toggle_javascript}
          #{chart_tooltip_javascript}
          #{global_behaviors_javascript}
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
              tooltip.classList.add('tooltip-visible');
              positionTooltip(e);
            });

            point.addEventListener('mousemove', function(e) {
              positionTooltip(e);
            });

            point.addEventListener('mouseleave', function() {
              tooltip.classList.remove('tooltip-visible');
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

            // Dynamic cursor-tracked position, not CSP-restricted.
            tooltip.style.left = x + 'px';
            tooltip.style.top = y + 'px';
          }
        })();
      JS
    end

    def global_behaviors_javascript
      <<-JS
        document.addEventListener('submit', function(e) {
          var form = e.target;
          var msg = form.dataset && form.dataset.confirm;
          if (msg && !window.confirm(msg)) { e.preventDefault(); }
        }, true);

        document.addEventListener('click', function(e) {
          var el = e.target.closest('[data-confirm-submit]');
          if (!el) return;
          e.preventDefault();
          var msg = el.dataset.confirm || 'Are you sure?';
          if (!window.confirm(msg)) return;
          var formId = el.dataset.confirmSubmit;
          var form = document.getElementById(formId);
          if (form) form.submit();
        });

        var timeRangeSelect = document.getElementById('chart-time-select');
        if (timeRangeSelect) {
          timeRangeSelect.addEventListener('change', function() {
            window.location.href = '?time_range=' + this.value;
          });
        }
      JS
    end

    def default_url_options
      { only_path: true }
    end
  end
end
