module SolidQueueMonitor
  class StatsPresenter
    def initialize(stats)
      @stats = stats
    end

    def render
      <<-HTML
        <div class="stats-container">
          <div class="stats">
            #{generate_stat_cards}
          </div>
        </div>
      HTML
    end

    private

    def generate_stat_cards
      @stats.map { |key, value|
        <<-HTML
          <div class="stat-card">
            <h3>#{humanize_key(key)}</h3>
            <p>#{value}</p>
          </div>
        HTML
      }.join
    end

    def humanize_key(key)
      key.to_s.humanize
    end
  end
end