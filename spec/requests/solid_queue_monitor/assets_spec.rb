# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GET /solid_queue/assets/:file' do
  before { SolidQueueMonitor::AssetCache.clear! }
  after { SolidQueueMonitor::AssetCache.clear! }

  let(:css_fingerprint) { SolidQueueMonitor::AssetCache.fingerprint_for('application.css') }
  let(:js_fingerprint) { SolidQueueMonitor::AssetCache.fingerprint_for('application.js') }

  it 'serves application.css with the correct fingerprint and content type' do
    get "/assets/application-#{css_fingerprint}.css"
    expect(response).to have_http_status(:ok)
    expect(response.content_type).to start_with('text/css')
    expect(response.headers['Cache-Control']).to include('immutable')
    expect(response.headers['Cache-Control']).to include("max-age=#{1.year.to_i}")
  end

  it 'serves application.js with the correct fingerprint and content type' do
    get "/assets/application-#{js_fingerprint}.js"
    expect(response).to have_http_status(:ok)
    expect(response.content_type).to start_with('application/javascript')
  end

  it 'returns 304 when If-None-Match matches the etag' do
    get "/assets/application-#{css_fingerprint}.css",
        headers: { 'If-None-Match' => %("#{css_fingerprint}") }
    expect(response).to have_http_status(:not_modified)
    expect(response.body).to be_empty
  end

  it 'returns 404 when the fingerprint does not match the file content' do
    get '/assets/application-deadbeefdeadbeef.css'
    expect(response).to have_http_status(:not_found)
  end

  it 'returns 404 (route does not match) when the file name lacks a hyphenated hash' do
    get '/assets/application.css'
    expect(response).to have_http_status(:not_found)
  end

  it 'returns 404 (route does not match) for disallowed extensions' do
    get "/assets/application-#{css_fingerprint}.html"
    expect(response).to have_http_status(:not_found)
  end

  it 'returns 404 (route does not match) for path-traversal attempts' do
    get '/assets/..%2F..%2Fetc%2Fpasswd'
    expect(response).to have_http_status(:not_found)
  end

  it 'serves assets without authentication even when auth is enabled' do
    SolidQueueMonitor.authentication_enabled = true
    get "/assets/application-#{css_fingerprint}.css"
    expect(response).to have_http_status(:ok)
  ensure
    SolidQueueMonitor.authentication_enabled = false
  end
end
