# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'redirect_to parameter' do
  unsafe_targets = [
    'https://evil.example',
    '//evil.example',
    '/\\evil.example',
    'javascript:alert(1)',
    'http://www.example.com/queues',
    # Same-site, but rejected by Rails' open-redirect check (a 500 before).
    '/a|b',
    '/café',
    '/%zz',
    "/a\u0001b"
  ]

  shared_examples 'a same-site redirect' do |fallback|
    it 'follows a path on this site' do
      perform('/queues/default?page=2')

      expect(response).to redirect_to('/queues/default?page=2')
    end

    unsafe_targets.each do |target|
      it "falls back to #{fallback} for #{target.inspect}" do
        perform(target)

        expect(response).to redirect_to(fallback)
      end
    end
  end

  context 'when the engine is mounted under a path' do
    def pause(target)
      post '/pause_queue', params: { queue_name: 'default', redirect_to: target },
                           env: { 'SCRIPT_NAME' => '/solid-queue-monitor' }
    end

    it 'follows a path inside the mount' do
      pause('/solid-queue-monitor/queues/default')

      expect(response.location).to eq('http://www.example.com/solid-queue-monitor/queues/default')
    end

    it 'falls back for a path in the host app' do
      pause('/out?url=https://evil.example')

      expect(response.location).to eq('http://www.example.com/solid-queue-monitor/queues')
    end
  end

  describe 'POST /retry_failed_job/:id' do
    def perform(target)
      post "/retry_failed_job/#{create(:solid_queue_failed_execution).id}", params: { redirect_to: target }
    end

    it_behaves_like 'a same-site redirect', '/failed_jobs'
  end

  describe 'POST /discard_failed_job/:id' do
    def perform(target)
      post "/discard_failed_job/#{create(:solid_queue_failed_execution).id}", params: { redirect_to: target }
    end

    it_behaves_like 'a same-site redirect', '/failed_jobs'
  end

  describe 'POST /execute_scheduled_job/:id' do
    def perform(target)
      post "/execute_scheduled_job/#{create(:solid_queue_scheduled_execution).id}", params: { redirect_to: target }
    end

    it_behaves_like 'a same-site redirect', '/scheduled_jobs'
  end

  describe 'POST /pause_queue' do
    def perform(target)
      post '/pause_queue', params: { queue_name: 'default', redirect_to: target }
    end

    it_behaves_like 'a same-site redirect', '/queues'
  end

  describe 'POST /resume_queue' do
    def perform(target)
      post '/resume_queue', params: { queue_name: 'default', redirect_to: target }
    end

    it_behaves_like 'a same-site redirect', '/queues'
  end
end
