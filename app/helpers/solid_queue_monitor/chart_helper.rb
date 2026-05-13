# frozen_string_literal: true

module SolidQueueMonitor
  # rubocop:disable Metrics/ModuleLength
  module ChartHelper
    CHART_WIDTH = 1200
    CHART_HEIGHT = 280
    PADDING = { top: 40, right: 30, bottom: 60, left: 60 }.freeze
    COLORS = {
      created: '#3b82f6',
      completed: '#10b981',
      failed: '#ef4444'
    }.freeze
    SERIES = %i[failed completed created].freeze

    def render_chart(data:, time_range: nil)
      context = chart_context(data, time_range)

      safe_join(
        [
          chart_section(context),
          chart_tooltip
        ]
      )
    end

    def chart_time_range_options
      SolidQueueMonitor::ChartDataService::TIME_RANGES.map do |key, config|
        [config[:label], key]
      end
    end

    private

    def chart_context(data, time_range)
      {
        data: data.merge(time_range: time_range || data[:time_range]),
        plot_width: CHART_WIDTH - PADDING[:left] - PADDING[:right],
        plot_height: CHART_HEIGHT - PADDING[:top] - PADDING[:bottom]
      }
    end

    def chart_section(context)
      tag.div(id: 'chart-section', class: 'chart-section') do
        safe_join(
          [
            chart_header(context),
            tag.div(id: 'chart-collapsible', class: 'chart-collapsible') do
              safe_join(
                [
                  tag.div(chart_body(context), class: 'chart-container'),
                  chart_legend
                ]
              )
            end
          ]
        )
      end
    end

    def chart_header(context)
      tag.div(class: 'chart-header') do
        safe_join(
          [
            tag.div(class: 'chart-header-left') do
              safe_join(
                [
                  chart_toggle_button,
                  tag.h3('Job Activity'),
                  chart_summary(context)
                ]
              )
            end,
            chart_time_select(context)
          ]
        )
      end
    end

    def chart_toggle_button
      tag.button(class: 'chart-toggle-btn', id: 'chart-toggle-btn', title: 'Toggle chart') do
        tag.svg(class: 'chart-toggle-icon',
                id: 'chart-toggle-icon',
                width: 16,
                height: 16,
                viewBox: '0 0 24 24',
                fill: 'none',
                stroke: 'currentColor',
                stroke_width: 2) do
          tag.polyline(points: '6 9 12 15 18 9')
        end
      end
    end

    def chart_summary(context)
      totals = context[:data][:totals] || { created: 0, completed: 0, failed: 0 }

      tag.span(class: 'chart-summary') do
        safe_join(
          [
            tag.span("#{totals[:created]} created", class: 'summary-item summary-created'),
            tag.span('.', class: 'summary-separator'),
            tag.span("#{totals[:completed]} completed", class: 'summary-item summary-completed'),
            tag.span('.', class: 'summary-separator'),
            tag.span("#{totals[:failed]} failed", class: 'summary-item summary-failed')
          ],
          ' '
        )
      end
    end

    def chart_time_select(context)
      options = context[:data][:available_ranges].map do |key, label|
        tag.option(label, value: key, selected: key == context[:data][:time_range])
      end

      tag.div(class: 'chart-time-select-wrapper') do
        tag.select(safe_join(options), class: 'chart-time-select', id: 'chart-time-select')
      end
    end

    def chart_body(context)
      return chart_empty_state if all_series_empty?(context)

      max_value = [calculate_max_value(context), 10].max

      tag.svg(viewBox: "0 0 #{CHART_WIDTH} #{CHART_HEIGHT}",
              class: 'job-activity-chart',
              preserveAspectRatio: 'xMidYMid meet') do
        safe_join(
          [
            chart_grid_lines(context),
            chart_axes,
            chart_x_labels(context),
            chart_y_labels(context, max_value),
            *SERIES.map { |series| series_line(context, series, max_value) },
            *SERIES.map { |series| series_points(context, series, max_value) }
          ].compact
        )
      end
    end

    def chart_empty_state
      tag.div(class: 'chart-empty') do
        tag.span('No job activity in this time range')
      end
    end

    def chart_grid_lines(context)
      safe_join(
        5.times.map do |index|
          y = PADDING[:top] + (context[:plot_height] * index / 4.0)
          tag.line(x1: PADDING[:left],
                   y1: y,
                   x2: CHART_WIDTH - PADDING[:right],
                   y2: y,
                   class: 'grid-line')
        end
      )
    end

    def chart_axes
      safe_join(
        [
          tag.line(x1: PADDING[:left],
                   y1: PADDING[:top],
                   x2: PADDING[:left],
                   y2: CHART_HEIGHT - PADDING[:bottom],
                   class: 'axis-line'),
          tag.line(x1: PADDING[:left],
                   y1: CHART_HEIGHT - PADDING[:bottom],
                   x2: CHART_WIDTH - PADDING[:right],
                   y2: CHART_HEIGHT - PADDING[:bottom],
                   class: 'axis-line')
        ]
      )
    end

    def chart_x_labels(context)
      labels = context[:data][:labels]
      return ''.html_safe if labels.blank?

      step = labels.size > 12 ? (labels.size / 6.0).ceil : 1
      safe_join(labels.each_with_index.filter_map do |label, index|
        next unless (index % step).zero? || index == labels.size - 1

        tag.text(label,
                 x: x_for_index(context, index, labels.size),
                 y: CHART_HEIGHT - PADDING[:bottom] + 20,
                 class: 'axis-label x-label')
      end)
    end

    def chart_y_labels(context, max_value)
      safe_join(
        5.times.map do |index|
          value = (max_value * (4 - index) / 4.0).round
          y = PADDING[:top] + (context[:plot_height] * index / 4.0)
          tag.text(value, x: PADDING[:left] - 10, y: y + 4, class: 'axis-label y-label')
        end
      )
    end

    def series_line(context, series, max_value)
      return if series_empty?(context, series)

      points = calculate_points(context, series, max_value)
      return if points.empty?

      tag.polyline(points: points.map { |point| "#{point[:x]},#{point[:y]}" }.join(' '),
                   class: "chart-line chart-line-#{series}",
                   fill: 'none',
                   stroke: COLORS[series],
                   stroke_width: 2)
    end

    def series_points(context, series, max_value)
      return if series_empty?(context, series)

      values = context[:data][series]
      safe_join(calculate_points(context, series, max_value).each_with_index.map do |point, index|
        tag.circle(cx: point[:x],
                   cy: point[:y],
                   r: 4,
                   class: "data-point data-point-#{series}",
                   fill: COLORS[series],
                   data: { series: series, label: context[:data][:labels][index], value: values[index] })
      end)
    end

    def chart_legend
      tag.div(class: 'chart-legend') do
        safe_join(%i[created completed failed].map do |series|
          tag.span(class: 'legend-item') do
            safe_join(
              [
                tag.span('', class: "legend-color legend-color-#{series}"),
                series.to_s.capitalize
              ],
              "\n"
            )
          end
        end)
      end
    end

    def chart_tooltip
      tag.div(id: 'chart-tooltip', class: 'chart-tooltip') do
        safe_join(
          [
            tag.div('', class: 'tooltip-label'),
            tag.div('', class: 'tooltip-value')
          ]
        )
      end
    end

    def all_series_empty?(context)
      %i[created completed failed].all? { |series| series_empty?(context, series) }
    end

    def series_empty?(context, series)
      context[:data][series].nil? || context[:data][series].all?(&:zero?)
    end

    def calculate_max_value(context)
      max = (context[:data][:created] + context[:data][:completed] + context[:data][:failed]).max || 0
      return 10 if max <= 10

      magnitude = 10**Math.log10(max).floor
      ((max.to_f / magnitude).ceil * magnitude)
    end

    def calculate_points(context, series, max_value)
      values = context[:data][series]
      return [] if values.blank?

      values.each_with_index.map do |value, index|
        {
          x: x_for_index(context, index, values.size).round(2),
          y: (CHART_HEIGHT - PADDING[:bottom] - (context[:plot_height] * value / max_value.to_f)).round(2)
        }
      end
    end

    def x_for_index(context, index, count)
      return PADDING[:left] if count <= 1

      PADDING[:left] + (context[:plot_width] * index / (count - 1).to_f)
    end
  end
  # rubocop:enable Metrics/ModuleLength
end
