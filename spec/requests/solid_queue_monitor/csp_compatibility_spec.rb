# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'CSP compatibility', type: :request do
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

    it 'emits <style> without nonce attribute' do
      get '/'
      expect(response.body).to match(/<style>/)
      expect(response.body).not_to match(/<style\s+nonce=/)
    end

    it 'emits <script> tags without nonce attribute' do
      get '/'
      response.body.scan(/<script[^>]*>/).each do |tag|
        expect(tag).not_to include('nonce=')
      end
    end
  end

  describe 'with a CSP nonce configured' do
    before do
      allow_any_instance_of(ActionController::Base)
        .to receive(:content_security_policy_nonce).and_return('test-nonce-123')
    end

    it 'stamps nonce on the <style> tag' do
      get '/'
      expect(response.body).to include('<style nonce="test-nonce-123">')
    end

    it 'stamps nonce on every <script> tag' do
      get '/'
      scripts = response.body.scan(/<script[^>]*>/)
      expect(scripts).not_to be_empty
      scripts.each { |tag| expect(tag).to include('nonce="test-nonce-123"') }
    end
  end
end
