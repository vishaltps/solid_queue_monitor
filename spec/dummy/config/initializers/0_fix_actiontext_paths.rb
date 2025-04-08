# frozen_string_literal: true

# Fix for the "can't modify frozen Array" error with ActionText in Rails 8.0.2
# This patch ensures we don't try to modify frozen arrays during initialization
if defined?(ActionText) && Rails.env.test?
  module ActionTextPathFix
    def self.apply
      # Create a safe duplicate of the frozen array if it exists
      if ActionText.respond_to?(:helpers_paths) && ActionText.helpers_paths.frozen?
        ActionText.instance_variable_set(:@helpers_paths, ActionText.helpers_paths.dup)
      end

      return unless ActionText.respond_to?(:models_paths) && ActionText.models_paths.frozen?

      ActionText.instance_variable_set(:@models_paths, ActionText.models_paths.dup)
    end
  end

  ActionTextPathFix.apply
end
