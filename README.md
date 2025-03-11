# SolidQueueMonitor

A lightweight, zero-dependency web interface for monitoring Solid Queue jobs in Rails applications.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'solid_queue_monitor'
```

```bash
bundle install
rails generate solid_queue_monitor:install
```

## Configuration

Edit `config/initializers/solid_queue_monitor.rb`:

```ruby
SolidQueueMonitor.setup do |config|
# Configure authentication credentials
config.username = 'your_username'
config.password = 'your_secure_password'
# Configure number of jobs to display per section
config.jobs_per_page = 50
end

```

## Usage

Visit `/queue` in your browser to access the monitor interface.

### Features

- Real-time queue statistics
- View recent, scheduled, and failed jobs
- Execute scheduled jobs immediately
- Monitor recurring jobs
- Basic authentication
- Mobile-responsive design

## Development

After checking out the repo, run:

```bash
$ bin/setup
$ bundle exec rspec
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b feature/my-new-feature`)
3. Add tests for your changes
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin feature/my-new-feature`)
6. Create new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0] - 2024-03-11

### Added

- Initial release
- Basic authentication
- Job statistics
- Recent jobs view
- Scheduled jobs view with execute capability
- Failed jobs view
- Recurring jobs view
- Mobile-responsive design
