# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidQueueMonitor::AssetCache do
  after { described_class.clear! }

  describe '.fetch_by_name' do
    it 'returns the asset content, mtime, and etag for a known CSS file' do
      result = described_class.fetch_by_name('application.css')
      expect(result).to include(:content, :mtime, :etag)
      expect(result[:content]).to be_a(String)
      expect(result[:etag]).to match(/\A[a-f0-9]{16}\z/)
    end

    it 'returns the asset content for a known JS file' do
      result = described_class.fetch_by_name('application.js')
      expect(result[:content]).to be_a(String)
    end

    it 'returns nil for unknown files' do
      expect(described_class.fetch_by_name('nonexistent.css')).to be_nil
    end

    it 'returns nil for files outside the asset root' do
      expect(described_class.fetch_by_name('../../../etc/passwd')).to be_nil
    end

    it 'reuses the cached entry when mtime is unchanged' do
      first = described_class.fetch_by_name('application.css')
      second = described_class.fetch_by_name('application.css')
      expect(first.object_id).to eq(second.object_id)
    end
  end

  describe '.fingerprint_for' do
    it 'returns the etag for a known file' do
      expect(described_class.fingerprint_for('application.css')).to match(/\A[a-f0-9]{16}\z/)
    end

    it 'returns nil for unknown files' do
      expect(described_class.fingerprint_for('nope.css')).to be_nil
    end

    it 'produces a stable fingerprint for unchanged content' do
      a = described_class.fingerprint_for('application.css')
      described_class.clear!
      b = described_class.fingerprint_for('application.css')
      expect(a).to eq(b)
    end
  end
end
