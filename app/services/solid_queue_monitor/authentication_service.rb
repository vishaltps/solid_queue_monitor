module SolidQueueMonitor
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