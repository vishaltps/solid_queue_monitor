# frozen_string_literal: true

module SolidQueueMonitor
  class ApplicationController < ActionController::Base
    include ActionController::HttpAuthentication::Basic::ControllerMethods
    include ActionController::Flash

    before_action :authenticate, if: -> { SolidQueueMonitor::AuthenticationService.authentication_required? }
    layout false
    skip_before_action :verify_authenticity_token

    def set_flash_message(message, type)
      # Store in instance variable for access in views
      @flash_message = message
      @flash_type = type

      # Try to use Rails flash if available
      begin
        flash[:notice] = message if type == :success
        flash[:alert] = message if type == :error
      rescue StandardError
        # Flash not available (e.g., no session middleware)
      end
    end

    private

    def authenticate
      authenticate_or_request_with_http_basic do |username, password|
        SolidQueueMonitor::AuthenticationService.authenticate(username, password)
      end
    end
  end
end
