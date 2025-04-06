# frozen_string_literal: true

module SolidQueueMonitor
  class Engine < ::Rails::Engine
    isolate_namespace SolidQueueMonitor

    config.autoload_paths << root.join('app', 'services')

    # Optional: Add eager loading for production
    config.eager_load_paths << root.join('app', 'services')

    initializer 'solid_queue_monitor.assets' do |app|
      # Optional: Add assets if needed
    end
  end
end
