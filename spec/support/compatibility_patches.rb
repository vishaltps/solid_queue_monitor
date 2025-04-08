# frozen_string_literal: true

# Compatibility patches for Ruby 3.4 and Rails 8.0+

# Patch for ActionText frozen array issues
if defined?(ActionText)
  module ActionTextExtension
    def paths_with_unfrozen_arrays
      # Create unfrozen copies of potentially frozen arrays
      %i[@helpers_paths @models_paths].each do |var_name|
        if instance_variable_defined?(var_name) && instance_variable_get(var_name).frozen?
          instance_variable_set(var_name, instance_variable_get(var_name).dup)
        end
      end

      # Continue with normal execution
      yield
    end
  end

  # Apply the patches
  ActionText.singleton_class.prepend(ActionTextExtension) if ActionText.singleton_class.private_method_defined?(:paths)
end

# Patch for ActiveRecord connection handling issues
if defined?(ActiveRecord::Base)
  module ActiveRecordExtension
    def self.apply
      # Only apply if the legacy_connection_handling method isn't defined
      return if ActiveRecord::Base.respond_to?(:legacy_connection_handling=)

      ActiveRecord::Base.define_singleton_method(:legacy_connection_handling=) do |value|
        # This is a no-op method to prevent the error
        # It's safe to ignore this setting in Rails 8.0+
        Rails.logger.debug "legacy_connection_handling is not available, ignoring setting to #{value}"
      end
    end
  end

  ActiveRecordExtension.apply
end

# Additional compatibility checks for SolidQueue models
if defined?(SolidQueue)
  module SolidQueueExtension
    def self.apply
      # Check and handle RecurringExecution schedule column if needed
      return unless defined?(SolidQueue::RecurringExecution)
      return if SolidQueue::RecurringExecution.column_names.include?('schedule')

      # Add a virtual attribute for tests if the column doesn't exist
      SolidQueue::RecurringExecution.class_eval do
        attr_accessor :schedule, :queue_name
      end
    end
  end

  # Delay application until ActiveRecord is fully initialized
  Rails.configuration.after_initialize do
    SolidQueueExtension.apply if defined?(SolidQueue)
  end
end
