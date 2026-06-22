# frozen_string_literal: true

require 'spec_helper'

# Real CSRF token generation needs a working session store with a key
# generator and cookie salts. The shared request app in spec_helper wires
# session middleware but none of that, so these specs build a small Rack stack
# around the engine and merge in the host application's env config (key
# generator, secret_key_base, cookie salts). Requests still hit the engine
# directly, so paths are engine-relative (e.g. "/queues").
RSpec.describe 'CSRF protection' do
  def build_app_with_session
    stack = SolidQueueMonitor::Engine
    stack = ActionDispatch::Session::CookieStore.new(stack, key: '_sqm_csrf_session')
    stack = ActionDispatch::Cookies.new(stack)

    lambda do |env|
      stack.call(Rails.application.env_config.merge(env))
    end
  end

  before { @app = build_app_with_session }

  describe 'default configuration' do
    it 'is disabled by default' do
      expect(SolidQueueMonitor.csrf_protection_enabled).to be(false)
    end
  end

  context 'when disabled (default)' do
    it 'allows a destructive POST without a token' do
      post '/pause_queue', params: { queue_name: 'default' }

      expect(response).to have_http_status(:found)
      expect(SolidQueue::Pause.exists?(queue_name: 'default')).to be(true)
    end

    it 'does not render CSRF meta tags' do
      get '/queues'

      expect(response.body).not_to include('name="csrf-token"')
    end

    it 'does not embed an authenticity_token in forms' do
      create(:solid_queue_job, queue_name: 'default')

      get '/queues'

      expect(response.body).not_to include('name="authenticity_token"')
    end
  end

  context 'when enabled' do
    around do |example|
      SolidQueueMonitor.csrf_protection_enabled = true
      original_protection = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = true
      example.run
    ensure
      ActionController::Base.allow_forgery_protection = original_protection
      SolidQueueMonitor.csrf_protection_enabled = false
    end

    it 'lets safe (GET) requests through' do
      get '/queues'

      expect(response).to have_http_status(:ok)
    end

    it 'renders CSRF meta tags in the layout' do
      get '/queues'

      expect(response.body).to include('name="csrf-token"')
    end

    it 'embeds an authenticity_token in destructive forms' do
      create(:solid_queue_job, queue_name: 'default')

      get '/queues'

      expect(response.body).to include('name="authenticity_token"')
    end

    it 'rejects a destructive POST without a token' do
      expect do
        post '/pause_queue', params: { queue_name: 'default' }
      end.to raise_error(ActionController::InvalidAuthenticityToken)

      expect(SolidQueue::Pause.exists?(queue_name: 'default')).to be(false)
    end

    it 'accepts a destructive POST carrying a valid token' do
      get '/queues'
      token = response.body[/<meta name="csrf-token" content="([^"]+)"/, 1]
      expect(token).to be_present

      post '/pause_queue', params: { queue_name: 'default', authenticity_token: token }

      expect(response).to have_http_status(:found)
      expect(SolidQueue::Pause.exists?(queue_name: 'default')).to be(true)
    end

    # Regression: enabling CSRF protection also turns on Rails' cross-origin
    # JavaScript guard (verify_same_origin_request). Since assets are served
    # from a controller, a plain GET for the JS asset would otherwise raise
    # ActionController::InvalidCrossOriginRequest. Assets are public and must
    # stay exempt from forgery protection.
    it 'serves the JS asset without a cross-origin request error' do
      SolidQueueMonitor::AssetCache.clear!
      fingerprint = SolidQueueMonitor::AssetCache.fingerprint_for('application.js')

      get "/assets/application-#{fingerprint}.js"

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to start_with('application/javascript')
    ensure
      SolidQueueMonitor::AssetCache.clear!
    end

    it 'serves the CSS asset' do
      SolidQueueMonitor::AssetCache.clear!
      fingerprint = SolidQueueMonitor::AssetCache.fingerprint_for('application.css')

      get "/assets/application-#{fingerprint}.css"

      expect(response).to have_http_status(:ok)
    ensure
      SolidQueueMonitor::AssetCache.clear!
    end
  end
end
