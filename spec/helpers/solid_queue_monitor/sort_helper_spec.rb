# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidQueueMonitor::SortHelper do
  describe '#sortable_header' do
    it 'returns a plain table header when sort is nil' do
      expect(helper.sortable_header(:class_name, 'Class', sort: nil)).to eq('<th>Class</th>')
    end

    it 'renders an active descending sort link when column matches' do
      sort = { sort_by: 'class_name', sort_direction: 'asc' }
      result = helper.sortable_header(:class_name, 'Class', sort: sort)

      expect(result).to include('class="sortable-header active"')
      expect(result).to include('sort_direction=desc')
      expect(result).to include(' &uarr;')
    end

    it 'renders an inactive ascending sort link when column does not match' do
      sort = { sort_by: 'queue_name', sort_direction: 'asc' }
      result = helper.sortable_header(:class_name, 'Class', sort: sort)

      expect(result).to include('class="sortable-header"')
      expect(result).to include('sort_direction=asc')
      expect(result).to include(' &udarr;')
    end

    it 'preserves filter params in the sort link' do
      sort = { sort_by: nil, sort_direction: nil }
      filters = { class_name: 'MyJob', status: 'failed' }
      result = helper.sortable_header(:created_at, 'Created', sort: sort, filters: filters)

      expect(result).to include('class_name=MyJob')
      expect(result).to include('status=failed')
    end
  end
end
