# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'CSP compatibility' do
  let(:inline_handler_pattern) { /\s(onclick|onchange|onsubmit|onfocus|onblur|oninput|onkeyup|onkeydown)=/ }

  before do
    create_list(:solid_queue_job, 2)
    create(:solid_queue_failed_execution)
    create(:solid_queue_scheduled_execution)
    create(:solid_queue_ready_execution)
  end

  shared_examples 'a CSP-safe page' do |path|
    it "#{path} has no inline event handlers" do
      get path
      expect(response).to have_http_status(:ok)
      matches = response.body.scan(inline_handler_pattern).flatten.uniq
      expect(matches).to be_empty,
                         "Found inline handler(s) at #{path}: #{matches.join(', ')}"
    end

    it "#{path} has no inline style attributes" do
      get path
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to match(/\sstyle="/),
                                   "Inline style= attribute found at #{path} (nonces do not apply to style attributes)"
    end
  end

  describe 'without a CSP nonce configured' do
    [
      '/',
      '/ready_jobs',
      '/in_progress_jobs',
      '/scheduled_jobs',
      '/recurring_jobs',
      '/failed_jobs',
      '/queues',
      '/workers'
    ].each do |path|
      include_examples 'a CSP-safe page', path
    end

    it 'emits the stylesheet without a nonce attribute' do
      get '/'
      expect(response.body).to match(%r{<link[^>]+rel="stylesheet"[^>]+href="/assets/application-[a-f0-9]{16}\.css"})
      expect(response.body).not_to match(/<link[^>]+rel="stylesheet"[^>]+nonce=/)
    end

    it 'emits external <script> tags without nonce attribute' do
      get '/'
      response.body.scan(/<script[^>]*>/).each do |tag|
        expect(tag).to include('src=')
        expect(tag).not_to include('nonce=')
      end
    end
  end

  describe 'with a CSP nonce configured' do
    before do
      allow_any_instance_of(ActionController::Base)
        .to receive(:content_security_policy_nonce).and_return('test-nonce-123')
    end

    it 'stamps nonce on the stylesheet tag' do
      get '/'
      stylesheet_tags = response.body.scan(/<link[^>]+rel="stylesheet"[^>]*>/)
      expect(stylesheet_tags).not_to be_empty
      expect(stylesheet_tags).to all(include('nonce="test-nonce-123"'))
    end

    it 'stamps nonce on every external <script> tag' do
      get '/'
      scripts = response.body.scan(/<script[^>]*>/)
      expect(scripts).not_to be_empty
      expect(scripts).to all(include('src='))
      expect(scripts).to all(include('nonce="test-nonce-123"'))
    end
  end
end
