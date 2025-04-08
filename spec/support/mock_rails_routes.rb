# frozen_string_literal: true

# Mock Rails application and routes for testing
module Rails
  def self.application
    @application ||= OpenStruct.new(
      routes: OpenStruct.new(
        url_helpers: Module.new do
          def root_path
            '/'
          end

          def ready_jobs_path
            '/ready_jobs'
          end

          def in_progress_jobs_path
            '/in_progress_jobs'
          end

          def scheduled_jobs_path
            '/scheduled_jobs'
          end

          def recurring_jobs_path
            '/recurring_jobs'
          end

          def failed_jobs_path
            '/failed_jobs'
          end

          def queues_path
            '/queues'
          end

          module_function :root_path, :ready_jobs_path, :in_progress_jobs_path,
                          :scheduled_jobs_path, :recurring_jobs_path, :failed_jobs_path,
                          :queues_path
        end
      )
    )
  end
end

# Mock SolidQueueMonitor::Engine for testing
module SolidQueueMonitor
  class Engine
    def self.routes
      OpenStruct.new(
        url_helpers: Module.new do
          def root_path
            '/'
          end

          def ready_jobs_path
            '/ready_jobs'
          end

          def in_progress_jobs_path
            '/in_progress_jobs'
          end

          def scheduled_jobs_path
            '/scheduled_jobs'
          end

          def recurring_jobs_path
            '/recurring_jobs'
          end

          def failed_jobs_path
            '/failed_jobs'
          end

          def queues_path
            '/queues'
          end

          module_function :root_path, :ready_jobs_path, :in_progress_jobs_path,
                          :scheduled_jobs_path, :recurring_jobs_path, :failed_jobs_path,
                          :queues_path
        end
      )
    end
  end
end
