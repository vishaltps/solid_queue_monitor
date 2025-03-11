module SolidQueueMonitor
  class Engine < ::Rails::Engine
    isolate_namespace SolidQueueMonitor

    initializer "solid_queue_monitor.assets" do |app|
      # Optional: Add assets if needed
    end
  end
end