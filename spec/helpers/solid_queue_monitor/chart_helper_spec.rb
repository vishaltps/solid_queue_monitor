# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidQueueMonitor::ChartHelper do
  describe '#render_chart' do
    let(:data) do
      {
        labels: ['00:00', '01:00', '02:00'],
        created: [5, 7, 10],
        completed: [4, 6, 9],
        failed: [1, 1, 1],
        totals: { created: 22, completed: 19, failed: 3 },
        time_range: '1d',
        available_ranges: { '1d' => 'Last 24 hours', '1w' => 'Last 7 days' }
      }
    end

    it 'renders an SVG with three data series' do
      result = helper.render_chart(data: data, time_range: '1d')

      expect(result).to include('<svg')
      expect(result).to include('data-series="created"')
      expect(result).to include('data-series="completed"')
      expect(result).to include('data-series="failed"')
    end

    it 'renders one data point per data row per series' do
      result = helper.render_chart(data: data, time_range: '1d')

      expect(result.scan('class="data-point data-point-').size).to eq(9)
    end

    it 'escapes data labels to prevent XSS' do
      hostile = data.merge(labels: ['<script>alert(1)</script>'], created: [1], completed: [1], failed: [1])
      result = helper.render_chart(data: hostile, time_range: '1d')

      expect(result).not_to include('<script>alert(1)</script>')
      expect(result).to include('&lt;script&gt;')
    end

    it 'renders an empty state when all series are empty' do
      empty_data = data.merge(created: [0], completed: [0], failed: [0])

      expect(helper.render_chart(data: empty_data, time_range: '1d')).to include('No job activity in this time range')
    end
  end

  describe '#chart_time_range_options' do
    it 'returns a list of labels and values' do
      options = helper.chart_time_range_options

      expect(options).to include(['Last 24 hours', '1d'])
      expect(options.size).to be >= 3
    end
  end
end
