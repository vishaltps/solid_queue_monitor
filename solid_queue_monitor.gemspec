# frozen_string_literal: true

require_relative 'lib/solid_queue_monitor/version'

Gem::Specification.new do |spec|
  spec.name = 'solid_queue_monitor'
  spec.version = SolidQueueMonitor::VERSION
  spec.authors = ['Vishal Sadriya']
  spec.email = ['vishalsadriya1224@gmail.com']

  spec.summary = 'Simple monitoring interface for Solid Queue'
  spec.description = 'A lightweight, zero-dependency web interface for monitoring Solid Queue jobs in Rails applications'
  spec.homepage = 'https://github.com/vishaltps/solid_queue_monitor'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['{app,config,lib}/**/*', 'LICENSE', 'Rakefile', 'README.md']
  spec.require_paths = ['lib']

  spec.add_dependency 'rails', '>= 7.0'
  spec.add_dependency 'solid_queue', '>= 0.1.0'
end
