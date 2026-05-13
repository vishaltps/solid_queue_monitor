# frozen_string_literal: true

module SolidQueueMonitor
  class SearchController < BaseController
    def index
      @query = params[:q]
      @results = SearchService.new(@query).search
      @total_count = @results.values.sum(&:size)
    end
  end
end
