# frozen_string_literal: true

require 'digest'

module SolidQueueMonitor
  class AssetCache
    ASSET_ROOT = SolidQueueMonitor::Engine.root.join('app/assets').freeze
    SUBDIRS_BY_EXT = { '.css' => 'stylesheets', '.js' => 'javascripts' }.freeze
    MUTEX = Mutex.new

    @entries = {}

    class << self
      def fetch_by_name(file_name)
        path = path_for(file_name)
        return nil unless path&.file?

        cached = @entries[path.to_s]
        return cached if cached && cached[:mtime] == path.mtime

        MUTEX.synchronize do
          cached = @entries[path.to_s]
          return cached if cached && cached[:mtime] == path.mtime

          content = path.read
          @entries[path.to_s] = {
            content: content,
            mtime: path.mtime,
            etag: Digest::SHA256.hexdigest(content)[0, 16]
          }
        end
      end

      def fingerprint_for(file_name)
        fetch_by_name(file_name)&.dig(:etag)
      end

      def clear!
        MUTEX.synchronize { @entries = {} }
      end

      private

      def path_for(file_name)
        ext = File.extname(file_name)
        subdir = SUBDIRS_BY_EXT[ext]
        return nil unless subdir

        candidate = ASSET_ROOT.join(subdir, 'solid_queue_monitor', file_name).expand_path
        return nil unless candidate.to_s.start_with?(ASSET_ROOT.to_s)

        candidate
      end
    end
  end
end
