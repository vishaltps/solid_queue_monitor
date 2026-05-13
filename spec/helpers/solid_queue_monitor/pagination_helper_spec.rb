# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidQueueMonitor::PaginationHelper do
  describe '#visible_pages' do
    it 'returns all pages when total is seven or fewer' do
      expect(helper.visible_pages(1, 5)).to eq([1, 2, 3, 4, 5])
    end

    it 'truncates the tail when current page is near the start' do
      expect(helper.visible_pages(2, 20)).to eq([1, 2, 3, 4, :gap, 20])
    end

    it 'truncates the head when current page is near the end' do
      expect(helper.visible_pages(19, 20)).to eq([1, :gap, 17, 18, 19, 20])
    end

    it 'truncates both sides when current page is in the middle' do
      expect(helper.visible_pages(10, 20)).to eq([1, :gap, 9, 10, 11, :gap, 20])
    end
  end
end
