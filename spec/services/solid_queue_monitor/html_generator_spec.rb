# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidQueueMonitor::HtmlGenerator do
  describe '#generate' do
    context 'when a nonce is supplied' do
      subject(:html) do
        described_class.new(title: 'Test', content: '<p>hello</p>', nonce: 'abc123').generate
      end

      it 'stamps the nonce on the <style> tag' do
        expect(html).to include('<style nonce="abc123">')
      end

      it 'stamps the nonce on every <script> tag' do
        scripts = html.scan(/<script[^>]*>/)
        expect(scripts).not_to be_empty
        expect(scripts).to all(include('nonce="abc123"'))
      end
    end

    context 'when no nonce is supplied' do
      subject(:html) do
        described_class.new(title: 'Test', content: '<p>hello</p>').generate
      end

      it 'emits <style> without a nonce attribute' do
        expect(html).to include('<style>')
        expect(html).not_to match(/<style\s+nonce=/)
      end

      it 'emits <script> tags without a nonce attribute' do
        scripts = html.scan(/<script[^>]*>/)
        expect(scripts.join).not_to include('nonce=')
      end
    end

    context 'when a flash message is rendered' do
      subject(:html) do
        described_class.new(
          title: 'Test',
          content: '<p>hi</p>',
          message: 'Done',
          message_type: 'success',
          nonce: 'xyz'
        ).generate
      end

      it 'stamps nonce on the flash-message <script>' do
        flash_script = html[%r{<script[^>]*>[^<]*flash-message[\s\S]*?</script>}]
        expect(flash_script).to include('nonce="xyz"')
      end
    end
  end
end
