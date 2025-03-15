module SolidQueueMonitor
  class StatsPresenter < BasePresenter
    def initialize(stats)
      @stats = stats
    end

    def render
      <<-HTML
        <div class="stats-container">
          <h3>Queue Statistics</h3>
          <div class="stats">
            #{generate_stat_card('Total Jobs', @stats[:total_jobs])}
            #{generate_stat_card('Unique Queues', @stats[:unique_queues])}
            #{generate_stat_card('Ready', @stats[:ready])}
            #{generate_stat_card('Scheduled', @stats[:scheduled])}
            #{generate_stat_card('Failed', @stats[:failed])}
            #{generate_stat_card('Completed', @stats[:completed])}
            #{generate_stat_card('Recurring', @stats[:recurring])}
          </div>
        </div>
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