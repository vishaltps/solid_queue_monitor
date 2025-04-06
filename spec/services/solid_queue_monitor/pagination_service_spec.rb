# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidQueueMonitor::PaginationService do
  describe '#paginate' do
    let!(:jobs) { create_list(:solid_queue_job, 30) }
    let(:relation) { SolidQueue::Job.all }

    context 'with default page size' do
      subject { described_class.new(relation, 1, 25) }

      it 'returns a hash with records, current_page, and total_pages' do
        result = subject.paginate

        expect(result).to be_a(Hash)
        expect(result).to include(:records, :current_page, :total_pages)
      end

      it 'limits records to the page size' do
        result = subject.paginate

        expect(result[:records].size).to eq(25)
      end

      it 'calculates total pages correctly' do
        result = subject.paginate

        expect(result[:total_pages]).to eq(2)
      end
    end

    context 'with custom page size' do
      subject { described_class.new(relation, 1, 10) }

      it 'limits records to the specified page size' do
        result = subject.paginate

        expect(result[:records].size).to eq(10)
        expect(result[:total_pages]).to eq(3)
      end
    end

    context 'with page navigation' do
      subject { described_class.new(relation, 2, 10) }

      it 'returns the correct page of records' do
        result = subject.paginate

        expect(result[:records].size).to eq(10)
        expect(result[:current_page]).to eq(2)

        # The records should be different from page 1
        page1 = described_class.new(relation, 1, 10).paginate[:records]
        expect(result[:records]).not_to eq(page1)
      end
    end

    context 'with empty relation' do
      subject { described_class.new(SolidQueue::Job.where(id: -1), 1, 25) }

      it 'returns empty records with correct pagination info' do
        result = subject.paginate

        expect(result[:records]).to be_empty
        expect(result[:current_page]).to eq(1)
        expect(result[:total_pages]).to eq(0)
      end
    end
  end
end
