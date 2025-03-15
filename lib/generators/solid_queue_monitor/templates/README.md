# SolidQueueMonitor Installation

The SolidQueueMonitor has been installed.

## Next Steps

1. Configure your settings in `config/initializers/solid_queue_monitor.rb`

2. Access your dashboard at: http://your-app-url/solid_queue

3. Authentication:
   - Authentication is disabled by default for ease of setup
   - To enable authentication, set `config.authentication_enabled = true` in the initializer
   - Default credentials (when authentication is enabled):
     - Username: admin
     - Password: password

## Security Note

For production environments, it's strongly recommended to:

1. Enable authentication
2. Change the default credentials to secure values
