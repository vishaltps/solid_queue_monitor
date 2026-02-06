# frozen_string_literal: true

module SolidQueueMonitor
  class SearchController < BaseController
    def index
      query = params[:q]
      results = SearchService.new(query).search

      render_page('Search', SearchResultsPresenter.new(query, results).render, search_query: query)
    end
  end
end
