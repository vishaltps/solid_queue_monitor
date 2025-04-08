# frozen_string_literal: true

# Mock SolidQueueMonitor module for testing
module SolidQueueMonitor
  class << self
    attr_accessor :username, :password, :authentication_enabled
  end

  @username = 'admin'
  @password = 'password'
  @authentication_enabled = false

  # Mock AuthenticationService
  class AuthenticationService
    def self.authenticate(username, password)
      return true unless SolidQueueMonitor.authentication_enabled

      username == SolidQueueMonitor.username &&
        password == SolidQueueMonitor.password
    end

    def self.authentication_required?
      SolidQueueMonitor.authentication_enabled
    end
  end
end
