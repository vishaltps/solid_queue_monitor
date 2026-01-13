# frozen_string_literal: true

module SolidQueueMonitor
  class Engine < ::Rails::Engine
    isolate_namespace SolidQueueMonitor

    config.autoload_paths << root.join('app', 'services')

    # Optional: Add eager loading for production
    config.eager_load_paths << root.join('app', 'services')

    # Ensure session middleware is available
    initializer 'solid_queue_monitor.middleware' do |app|
      app.config.session_store :cookie_store, key: '_solid_queue_monitor_session' unless app.config.session_store
    end

    initializer 'solid_queue_monitor.assets' do |app|
      # Optional: Add assets if needed
    end
  end
end
