# frozen_string_literal: true

module SolidQueueMonitor
  class StatsPresenter < BasePresenter
    def initialize(stats)
      @stats = stats
    end

    def render
      auto_refresh_enabled = SolidQueueMonitor.auto_refresh_enabled
      auto_refresh_interval = SolidQueueMonitor.auto_refresh_interval
      <<-HTML
        <div class="stats-container">
          <h3 style='margin-top:1rem;margin-bottom:1rem'>Queue Statistics</h3>
          <div class="stats" id="stats-content">
            #{generate_stat_card('Total Jobs', @stats[:total_jobs])}
            #{generate_stat_card('Ready', @stats[:ready])}
            #{generate_stat_card('In Progress', @stats[:in_progress])}
            #{generate_stat_card('Scheduled', @stats[:scheduled])}
            #{generate_stat_card('Recurring', @stats[:recurring])}
            #{generate_stat_card('Failed', @stats[:failed])}
            #{generate_stat_card('Completed', @stats[:completed])}
          </div>
        </div>
        <script>
        document.addEventListener('DOMContentLoaded', function() {
          var autoRefreshEnabled = #{auto_refresh_enabled};
          var autoRefreshInterval = #{auto_refresh_interval};
          var intervalId = null;

          function fetchStats() {
            fetch(window.location.pathname + '?stats_only=1', { headers: { 'X-Requested-With': 'XMLHttpRequest' } })
              .then(function(response) { return response.text(); })
              .then(function(html) {
                var parser = new DOMParser();
                var doc = parser.parseFromString(html, 'text/html');
                var newStats = doc.getElementById('stats-content');
                if (newStats) {
                  document.getElementById('stats-content').innerHTML = newStats.innerHTML;
                }
              });
          }

          function startAutoRefresh() {
            if (intervalId) clearInterval(intervalId);
            if (autoRefreshEnabled) {
              intervalId = setInterval(fetchStats, autoRefreshInterval);
            }
          }

          if (autoRefreshEnabled) {
            startAutoRefresh();
          }
        });
        </script>
      HTML
    end

    private

    def generate_stat_card(title, value)
      <<-HTML
        <div class="stat-card">
          <h3>#{title}</h3>
          <p>#{value}</p>
        </div>
      HTML
    end
  end
end
