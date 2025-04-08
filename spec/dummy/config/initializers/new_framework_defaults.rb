# frozen_string_literal: true

# Configure Rails 8.0+ features and handle deprecation warnings

# Set to_time to preserve timezone as recommended in the deprecation warning
# This addresses: "DEPRECATION WARNING: `to_time` will always preserve the full timezone
# rather than offset of the receiver in Rails 8.1"
Rails.application.config.active_support.to_time_preserves_timezone = :zone if Rails.version >= '8.0'
