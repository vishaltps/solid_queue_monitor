# frozen_string_literal: true

require 'rails_helper'
require 'ostruct'

# Mock SolidQueueMonitor module
module SolidQueueMonitor
  def self.jobs_per_page
    10
  end

  # Mock SolidQueueMonitor::TestBaseController for testing
  class TestBaseController < ActionController::Base
    def paginate(relation)
      { records: relation, current_page: 1, total_pages: 1 }
    end

    def filter_jobs(relation)
      relation
    end

    def current_page
      1
    end

    def per_page
      SolidQueueMonitor.jobs_per_page
    end

    def render_page(title, content)
      html = "<html><head><title>#{title}</title></head><body>#{content}</body></html>"
      render html: html.html_safe
    end

    # Mock HtmlGenerator for testing
    class HtmlGenerator
      def initialize(title:, content:, message: nil, message_type: nil)
        @title = title
        @content = content
        @message = message
        @message_type = message_type
      end

      def generate
        "<html><head><title>#{@title}</title></head><body>#{@message}#{@content}</body></html>"
      end
    end

    # Mock StatsCalculator
    class StatsCalculator
      def self.calculate
        {
          total_jobs: 10,
          ready_jobs: 5,
          scheduled_jobs: 2,
          failed_jobs: 1,
          in_progress_jobs: 2
        }
      end
    end

    # Mock presenters
    class StatsPresenter
      def initialize(stats)
        @stats = stats
      end

      def render
        "<div class='stats'>Stats</div>"
      end
    end

    class JobsPresenter
      def initialize(jobs, current_page: 1, total_pages: 1, filters: {})
        @jobs = jobs
        @current_page = current_page
        @total_pages = total_pages
        @filters = filters
      end

      def render
        "<div class='jobs'>Jobs List</div>"
      end
    end
  end
end

# Define Rails module for testing
module Rails
  def self.application
    OpenStruct.new(routes: OpenStruct.new(url_helpers: nil))
  end
end

# Create a basic test controller
class TestController < SolidQueueMonitor::TestBaseController
  def index
    render_page('Test Title', 'Test Content')
  end
end

RSpec.describe TestController, type: :controller do
  describe '#index' do
    it 'renders a page with title and content' do
      get :index
      expect(response.body).to include('Test Title')
      expect(response.body).to include('Test Content')
    end
  end
end
