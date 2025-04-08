# frozen_string_literal: true

# This file provides mocks for controllers and related classes
# without depending on the actual Rails Engine

require 'ostruct'

# Create base controller classes for controller tests
module SolidQueueMonitor
  # Mock BaseController
  class MockBaseController
    attr_reader :params, :request, :response, :flash

    def initialize
      @params = {}
      @request = OpenStruct.new(
        headers: {},
        env: {},
        path: '/'
      )
      @response = OpenStruct.new(
        status: 200,
        body: '',
        headers: {}
      )
      @flash = {}
    end

    def render(options = {})
      @response.body = options[:html] || options[:json]&.to_json || "Rendered #{options[:template] || 'unknown'}"
      @response
    end

    def redirect_to(path, options = {})
      @response.status = options[:status] || 302
      @response.headers['Location'] = path
      @response
    end

    def authenticate_user!
      # Mock authentication
      true
    end

    # Helper for tests to set params
    def set_params(new_params)
      @params = new_params
    end
  end

  # Mock for ApplicationController
  class MockApplicationController < MockBaseController
    def authenticate_user!
      return true unless SolidQueueMonitor.authentication_required?

      authenticate_with_http_basic do |username, password|
        SolidQueueMonitor::AuthenticationService.authenticate(username, password)
      end
    end

    def authenticate_with_http_basic
      auth_header = request.headers['Authorization']
      if auth_header && auth_header.start_with?('Basic ')
        credentials = Base64.decode64(auth_header.sub('Basic ', '')).split(':')
        yield(credentials[0], credentials[1])
      else
        false
      end
    end
  end

  # Mock for various controllers
  class MockOverviewController < MockApplicationController
    def index
      render html: '<html><body>Overview Page</body></html>'
    end
  end

  class MockReadyJobsController < MockApplicationController
    def index
      render html: '<html><body>Ready Jobs</body></html>'
    end
  end
end

# Mock request specs
module MockRequest
  def get(_path, headers = {})
    controller = SolidQueueMonitor::MockApplicationController.new
    controller.request.headers.merge!(headers)
    controller.response
  end

  def post(_path, params = {}, headers = {})
    controller = SolidQueueMonitor::MockApplicationController.new
    controller.set_params(params)
    controller.request.headers.merge!(headers)
    controller.response
  end
end
