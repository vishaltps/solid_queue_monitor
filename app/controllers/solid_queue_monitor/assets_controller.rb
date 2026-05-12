# frozen_string_literal: true

module SolidQueueMonitor
  class AssetsController < ApplicationController
    skip_before_action :authenticate, raise: false

    MIME_TYPES = { '.css' => 'text/css', '.js' => 'application/javascript' }.freeze
    FINGERPRINT_PATTERN = /\A(?<base>[A-Za-z0-9_]+)-(?<hash>[a-f0-9]+)(?<ext>\.css|\.js)\z/

    def show
      asset_request = parse_asset_request
      return head(:not_found) unless asset_request

      asset = SolidQueueMonitor::AssetCache.fetch_by_name(asset_request[:file_name])
      return head(:not_found) unless asset
      return head(:not_found) unless fingerprint_matches?(asset[:etag], asset_request[:hash])

      assign_asset_headers(asset)
      return head(:not_modified) if etag_matches?

      render plain: asset[:content], content_type: MIME_TYPES[asset_request[:ext]]
    end

    private

    def parse_asset_request
      match = FINGERPRINT_PATTERN.match(params[:file])
      return nil unless match

      {
        ext: match[:ext],
        file_name: "#{match[:base]}#{match[:ext]}",
        hash: match[:hash]
      }
    end

    def fingerprint_matches?(expected, actual)
      expected.bytesize == actual.bytesize && Rack::Utils.secure_compare(expected, actual)
    end

    def assign_asset_headers(asset)
      response.headers['Cache-Control'] = "public, max-age=#{1.year.to_i}, immutable"
      response.headers['ETag'] = %("#{asset[:etag]}")
      response.headers['Last-Modified'] = asset[:mtime].httpdate
      response.headers['Vary'] = 'Accept-Encoding'
    end

    def etag_matches?
      request.headers['If-None-Match'].to_s.split(',').map(&:strip).include?(response.headers['ETag'])
    end
  end
end
