# frozen_string_literal: true

module SolidQueueMonitor
  module ApplicationHelper
    def asset_url_for(file_name)
      base = File.basename(file_name, '.*')
      ext = File.extname(file_name)
      hash = SolidQueueMonitor::AssetCache.fingerprint_for(file_name)
      fingerprinted_file = "#{base}-#{hash}#{ext}"

      if respond_to?(:solid_queue_monitor)
        solid_queue_monitor.asset_path(file: fingerprinted_file)
      else
        SolidQueueMonitor::Engine.routes.url_helpers.asset_path(file: fingerprinted_file)
      end
    end

    def format_datetime(datetime)
      return '-' unless datetime

      datetime.strftime('%Y-%m-%d %H:%M:%S')
    end

    def message_class(type)
      type.to_s == 'success' ? 'message-success' : 'message-error'
    end

    # Hidden authenticity_token field for raw HTML POST forms.
    # Renders nothing unless CSRF protection is enabled, so hosts without a
    # session store are unaffected (form_authenticity_token needs a session).
    def csrf_token_field_if_enabled
      return ''.html_safe unless SolidQueueMonitor.csrf_protection_enabled

      hidden_field_tag(:authenticity_token, form_authenticity_token)
    end

    # CSRF meta tags for JS/fetch-driven POSTs (defense in depth).
    # Only emitted when CSRF protection is enabled, for the same reason.
    def csrf_meta_tags_if_enabled
      return ''.html_safe unless SolidQueueMonitor.csrf_protection_enabled

      csrf_meta_tags
    end

    def queue_link(queue_name, css_class: nil)
      return '-' if queue_name.blank?

      link_to(queue_name,
              queue_details_url_for(queue_name),
              class: class_names('queue-link', css_class))
    end

    private

    def queue_details_url_for(queue_name)
      if respond_to?(:queue_details_path)
        queue_details_path(queue_name: queue_name)
      else
        SolidQueueMonitor::Engine.routes.url_helpers.queue_details_path(queue_name: queue_name)
      end
    end
  end
end
