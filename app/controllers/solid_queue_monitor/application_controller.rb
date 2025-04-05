# frozen_string_literal: true

module SolidQueueMonitor
  class ApplicationController < ActionController::Base
    include ActionController::HttpAuthentication::Basic::ControllerMethods
    include ActionController::Flash

    before_action :authenticate, if: -> { SolidQueueMonitor::AuthenticationService.authentication_required? }
    layout false
    skip_before_action :verify_authenticity_token

    def set_flash_message(message, type)
      session[:flash_message] = message
      session[:flash_type] = type
    end

    private

    def authenticate
      authenticate_or_request_with_http_basic do |username, password|
        SolidQueueMonitor::AuthenticationService.authenticate(username, password)
      end
    end
  end
end
