# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidQueueMonitor::ApplicationHelper do
  before { SolidQueueMonitor::AssetCache.clear! }

  describe '#asset_url_for' do
    it 'embeds the content fingerprint in the URL for a CSS file' do
      url = helper.asset_url_for('application.css')
      expect(url).to match(%r{/assets/application-[a-f0-9]{16}\.css\z})
    end

    it 'embeds the content fingerprint in the URL for a JS file' do
      url = helper.asset_url_for('application.js')
      expect(url).to match(%r{/assets/application-[a-f0-9]{16}\.js\z})
    end
  end

  describe '#format_datetime' do
    it 'formats a Time object as YYYY-MM-DD HH:MM:SS' do
      time = Time.zone.local(2026, 5, 12, 9, 30, 15)
      expect(helper.format_datetime(time)).to eq('2026-05-12 09:30:15')
    end

    it 'returns a dash for nil' do
      expect(helper.format_datetime(nil)).to eq('-')
    end
  end

  describe '#message_class' do
    it 'returns message-success for success' do
      expect(helper.message_class('success')).to eq('message-success')
    end

    it 'returns message-error for any other value' do
      expect(helper.message_class('error')).to eq('message-error')
      expect(helper.message_class(nil)).to eq('message-error')
    end
  end

  describe '#queue_link' do
    it 'renders a link to the queue details page' do
      result = helper.queue_link('default')
      expect(result).to include('href="/queues/default"')
      expect(result).to include('class="queue-link"')
      expect(result).to include('>default<')
    end

    it 'returns a dash for blank queue names' do
      expect(helper.queue_link(nil)).to eq('-')
      expect(helper.queue_link('')).to eq('-')
    end

    it 'merges in additional CSS classes' do
      result = helper.queue_link('default', css_class: 'highlight')
      expect(result).to include('class="queue-link highlight"')
    end
  end
end
