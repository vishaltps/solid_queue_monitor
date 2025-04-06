# frozen_string_literal: true

require 'rails/generators/base'

module SolidQueueMonitor
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      def copy_initializer
        template 'initializer.rb', 'config/initializers/solid_queue_monitor.rb'
      end

      def add_routes
        prepend_to_file 'config/routes.rb', "require 'solid_queue_monitor'\n\n"

        route "mount SolidQueueMonitor::Engine => '/solid_queue'"
      end

      def show_readme
        readme 'README.md' if behavior == :invoke
      end
    end
  end
end
