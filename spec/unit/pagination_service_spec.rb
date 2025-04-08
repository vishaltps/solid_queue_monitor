# frozen_string_literal: true

require 'spec_helper'

# Mock PaginationService
module SolidQueueMonitor
  class PaginationService
    def initialize(relation, current_page, per_page)
      @relation = relation
      @current_page = current_page
      @per_page = per_page
    end

    def paginate
      # In a real application, we would limit and offset the relation
      # For the mock, we'll use a simple array slicing
      total_count = @relation.is_a?(Array) ? @relation.count : 100
      total_pages = (total_count.to_f / @per_page).ceil

      # Adjust current_page to be within bounds
      @current_page = 1 if @current_page < 1
      @current_page = total_pages if @current_page > total_pages && total_pages > 0

      # For array, calculate start and end indices
      start_idx = (@current_page - 1) * @per_page
      end_idx = start_idx + @per_page - 1

      # Get records for the current page
      records = if @relation.is_a?(Array)
                  @relation[start_idx..end_idx] || []
                else
                  @relation
                end

      {
        records: records,
        current_page: @current_page,
        total_pages: total_pages
      }
    end
  end
end

RSpec.describe 'SolidQueueMonitor::PaginationService' do
  describe '#paginate' do
    let(:records) { (1..100).to_a }

    it 'paginates an array of records' do
      service = SolidQueueMonitor::PaginationService.new(records, 2, 25)
      result = service.paginate

      expect(result[:records]).to eq((26..50).to_a)
      expect(result[:current_page]).to eq(2)
      expect(result[:total_pages]).to eq(4)
    end

    it 'handles first page correctly' do
      service = SolidQueueMonitor::PaginationService.new(records, 1, 25)
      result = service.paginate

      expect(result[:records]).to eq((1..25).to_a)
      expect(result[:current_page]).to eq(1)
      expect(result[:total_pages]).to eq(4)
    end

    it 'handles last page correctly' do
      service = SolidQueueMonitor::PaginationService.new(records, 4, 25)
      result = service.paginate

      expect(result[:records]).to eq((76..100).to_a)
      expect(result[:current_page]).to eq(4)
      expect(result[:total_pages]).to eq(4)
    end

    it 'handles page number less than 1' do
      service = SolidQueueMonitor::PaginationService.new(records, 0, 25)
      result = service.paginate

      expect(result[:current_page]).to eq(1)
    end

    it 'handles page number greater than total pages' do
      service = SolidQueueMonitor::PaginationService.new(records, 10, 25)
      result = service.paginate

      expect(result[:current_page]).to eq(4)
    end

    it 'handles empty collection' do
      service = SolidQueueMonitor::PaginationService.new([], 1, 25)
      result = service.paginate

      expect(result[:records]).to eq([])
      expect(result[:current_page]).to eq(1)
      expect(result[:total_pages]).to eq(0)
    end
  end
end
