# frozen_string_literal: true

require_relative "lib/solid_queue_monitor/version"

Gem::Specification.new do |spec|
  spec.name = "solid_queue_monitor"
  spec.version = SolidQueueMonitor::VERSION
  spec.authors = ["Vishal Sadriya"]
  spec.email = ["vishalsadriya1224@gmail.com"]

  spec.summary = "Simple monitoring interface for Solid Queue"
  spec.description = "A lightweight, zero-dependency web interface for monitoring Solid Queue jobs in Rails applications"
  spec.homepage = "https://github.com/vishaltps/solid_queue_monitor"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.6"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  # spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
  #   ls.readlines("\x0", chomp: true).reject do |f|
  #     (f == gemspec) ||
  #       f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
  #   end
  # end
  spec.files = Dir["{app,config,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "rails", ">= 7.1"
  spec.add_dependency "solid_queue", ">= 0.1.0"
  
  spec.add_development_dependency "rspec-rails", "~> 6.0"
  spec.add_development_dependency "capybara", "~> 3.39"
  spec.add_development_dependency "sqlite3", "~> 1.6"
  spec.add_development_dependency "puma", "~> 6.0"
  spec.add_development_dependency "rubocop", "~> 1.60"
  spec.add_development_dependency "rubocop-rails", "~> 2.23"
  spec.add_development_dependency "rubocop-rspec", "~> 2.26"
  spec.add_development_dependency "factory_bot_rails", "~> 6.2"
  spec.add_development_dependency "database_cleaner-active_record", "~> 2.1"
  spec.add_development_dependency "pry", "~> 0.14"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
