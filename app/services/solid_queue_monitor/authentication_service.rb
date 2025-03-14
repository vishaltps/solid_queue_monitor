module SolidQueueMonitor
  class AuthenticationService
    def self.authenticate(username, password)
      username == SolidQueueMonitor.username &&
      password == SolidQueueMonitor.password
    end
  end
end