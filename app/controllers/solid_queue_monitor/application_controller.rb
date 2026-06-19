# frozen_string_literal: true

module SolidQueueMonitor
  class ApplicationController < SolidQueueMonitor.base_controller_class.safe_constantize || ActionController::Base
    include ActionController::HttpAuthentication::Basic::ControllerMethods
    include ActionController::Flash

    # Explicitly include the engine's helpers so they remain available when the
    # host configures a custom base_controller_class. Rails auto-includes engine
    # helpers only when the parent is ActionController::Base; inheriting from a
    # host controller short-circuits that, breaking view methods like render_chart.
    helper SolidQueueMonitor::Engine.helpers

    before_action :authenticate, if: -> { SolidQueueMonitor::AuthenticationService.authentication_required? }
    layout 'solid_queue_monitor/application'

    # CSRF protection is opt-in (config.csrf_protection_enabled). By default the
    # token check is skipped so the dashboard works in hosts without a session
    # store. When the host enables it, the standard verify_authenticity_token
    # before_action runs and unverified POSTs are rejected.
    skip_before_action :verify_authenticity_token, unless: -> { SolidQueueMonitor.csrf_protection_enabled }

    def set_flash_message(message, type)
      # Store in instance variable for access in views
      @flash_message = message
      @flash_type = type

      # Try to use Rails flash if available
      begin
        flash[:notice] = message if type == :success
        flash[:alert]  = message if type == :error
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
