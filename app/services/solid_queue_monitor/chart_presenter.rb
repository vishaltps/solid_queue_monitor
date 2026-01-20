# frozen_string_literal: true

module SolidQueueMonitor
  class ChartPresenter
    CHART_WIDTH = 1200
    CHART_HEIGHT = 280
    PADDING = { top: 40, right: 30, bottom: 60, left: 60 }.freeze
    COLORS = {
      created: '#3b82f6',   # Blue
      completed: '#10b981', # Green
      failed: '#ef4444'     # Red
    }.freeze

    def initialize(chart_data)
      @data = chart_data
      @plot_width = CHART_WIDTH - PADDING[:left] - PADDING[:right]
      @plot_height = CHART_HEIGHT - PADDING[:top] - PADDING[:bottom]
    end

    def render
      <<-HTML
        <div class="chart-section" id="chart-section">
          <div class="chart-header">
            <div class="chart-header-left">
              <button class="chart-toggle-btn" id="chart-toggle-btn" title="Toggle chart">
                <svg class="chart-toggle-icon" id="chart-toggle-icon" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <polyline points="6 9 12 15 18 9"></polyline>
                </svg>
              </button>
              <h3>Job Activity</h3>
              #{render_summary}
            </div>
            #{render_time_select}
          </div>
          <div class="chart-collapsible" id="chart-collapsible">
            <div class="chart-container">
              #{render_svg}
            </div>
            #{render_legend}
          </div>
        </div>
        #{render_tooltip}
      HTML
    end

    private

    def render_summary
      totals = @data[:totals] || { created: 0, completed: 0, failed: 0 }
      <<-HTML
        <span class="chart-summary">
          <span class="summary-item summary-created">#{totals[:created]} created</span>
          <span class="summary-separator">·</span>
          <span class="summary-item summary-completed">#{totals[:completed]} completed</span>
          <span class="summary-separator">·</span>
          <span class="summary-item summary-failed">#{totals[:failed]} failed</span>
        </span>
      HTML
    end

    def render_time_select
      options = @data[:available_ranges].map do |key, label|
        selected = key == @data[:time_range] ? 'selected' : ''
        "<option value=\"#{key}\" #{selected}>#{label}</option>"
      end.join

      <<-HTML
        <div class="chart-time-select-wrapper">
          <select class="chart-time-select" id="chart-time-select" onchange="window.location.href='?time_range=' + this.value">
            #{options}
          </select>
        </div>
      HTML
    end

    def render_svg
      return render_empty_state if all_series_empty?

      max_value = calculate_max_value
      max_value = 10 if max_value.zero?

      <<-SVG
        <svg viewBox="0 0 #{CHART_WIDTH} #{CHART_HEIGHT}" class="job-activity-chart" preserveAspectRatio="xMidYMid meet">
          #{render_grid_lines(max_value)}
          #{render_axes}
          #{render_x_labels}
          #{render_y_labels(max_value)}
          #{render_series_line(:failed, max_value)}
          #{render_series_line(:completed, max_value)}
          #{render_series_line(:created, max_value)}
          #{render_series_points(:failed, max_value)}
          #{render_series_points(:completed, max_value)}
          #{render_series_points(:created, max_value)}
        </svg>
      SVG
    end

    def all_series_empty?
      %i[created completed failed].all? { |series| series_empty?(series) }
    end

    def series_empty?(series)
      @data[series].nil? || @data[series].all?(&:zero?)
    end

    def render_empty_state
      <<-HTML
        <div class="chart-empty">
          <span>No job activity in this time range</span>
        </div>
      HTML
    end

    def render_series_line(series, max_value)
      return '' if series_empty?(series)

      render_line(series, max_value)
    end

    def render_series_points(series, max_value)
      return '' if series_empty?(series)

      render_data_points(series, max_value)
    end

    def calculate_max_value
      all_values = @data[:created] + @data[:completed] + @data[:failed]
      max = all_values.max || 0
      # Round up to nice number
      return 10 if max <= 10

      magnitude = 10**Math.log10(max).floor
      ((max.to_f / magnitude).ceil * magnitude)
    end

    def render_grid_lines(_max_value)
      lines = []
      5.times do |i|
        y = PADDING[:top] + (@plot_height * i / 4.0)
        lines << "<line x1=\"#{PADDING[:left]}\" y1=\"#{y}\" x2=\"#{CHART_WIDTH - PADDING[:right]}\" y2=\"#{y}\" class=\"grid-line\"/>"
      end
      lines.join("\n")
    end

    def render_axes
      <<-SVG
        <line x1="#{PADDING[:left]}" y1="#{PADDING[:top]}" x2="#{PADDING[:left]}" y2="#{CHART_HEIGHT - PADDING[:bottom]}" class="axis-line"/>
        <line x1="#{PADDING[:left]}" y1="#{CHART_HEIGHT - PADDING[:bottom]}" x2="#{CHART_WIDTH - PADDING[:right]}" y2="#{CHART_HEIGHT - PADDING[:bottom]}" class="axis-line"/>
      SVG
    end

    def render_x_labels
      labels = @data[:labels]
      return '' if labels.empty?

      # Show fewer labels if too many
      step = labels.size > 12 ? (labels.size / 6.0).ceil : 1

      label_elements = labels.each_with_index.map do |label, i|
        next unless (i % step).zero? || i == labels.size - 1

        x = PADDING[:left] + (@plot_width * i / (labels.size - 1).to_f)
        "<text x=\"#{x}\" y=\"#{CHART_HEIGHT - PADDING[:bottom] + 20}\" class=\"axis-label x-label\">#{label}</text>"
      end.compact

      label_elements.join("\n")
    end

    def render_y_labels(max_value)
      labels = []
      5.times do |i|
        value = (max_value * (4 - i) / 4.0).round
        y = PADDING[:top] + (@plot_height * i / 4.0)
        labels << "<text x=\"#{PADDING[:left] - 10}\" y=\"#{y + 4}\" class=\"axis-label y-label\">#{value}</text>"
      end
      labels.join("\n")
    end

    def render_line(series, max_value)
      points = calculate_points(series, max_value)
      return '' if points.empty?

      points_str = points.map { |p| "#{p[:x]},#{p[:y]}" }.join(' ')

      "<polyline points=\"#{points_str}\" class=\"chart-line chart-line-#{series}\" fill=\"none\" stroke=\"#{COLORS[series]}\" stroke-width=\"2\"/>"
    end

    def render_data_points(series, max_value)
      points = calculate_points(series, max_value)
      values = @data[series]

      points.each_with_index.map do |point, i|
        <<-SVG
          <circle cx="#{point[:x]}" cy="#{point[:y]}" r="4" class="data-point data-point-#{series}" fill="#{COLORS[series]}"
            data-series="#{series}" data-label="#{@data[:labels][i]}" data-value="#{values[i]}"/>
        SVG
      end.join("\n")
    end

    def calculate_points(series, max_value)
      values = @data[series]
      return [] if values.blank?

      values.each_with_index.map do |value, i|
        x = PADDING[:left] + (@plot_width * i / (values.size - 1).to_f)
        y = CHART_HEIGHT - PADDING[:bottom] - (@plot_height * value / max_value.to_f)
        { x: x.round(2), y: y.round(2) }
      end
    end

    def render_legend
      <<-HTML
        <div class="chart-legend">
          <span class="legend-item">
            <span class="legend-color" style="background-color: #{COLORS[:created]}"></span>
            Created
          </span>
          <span class="legend-item">
            <span class="legend-color" style="background-color: #{COLORS[:completed]}"></span>
            Completed
          </span>
          <span class="legend-item">
            <span class="legend-color" style="background-color: #{COLORS[:failed]}"></span>
            Failed
          </span>
        </div>
      HTML
    end

    def render_tooltip
      <<-HTML
        <div id="chart-tooltip" class="chart-tooltip" style="display: none;">
          <div class="tooltip-label"></div>
          <div class="tooltip-value"></div>
        </div>
      HTML
    end
  end
end
