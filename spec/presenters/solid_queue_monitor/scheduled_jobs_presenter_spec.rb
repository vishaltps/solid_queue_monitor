# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidQueueMonitor::ScheduledJobsPresenter do
  let(:job) { create(:solid_queue_job) }
  let(:scheduled_execution) { create(:solid_queue_scheduled_execution, job: job) }
  let(:jobs) { [scheduled_execution] }

  describe 'CSP nonce propagation' do
    it 'stamps nonce on its inline <script>' do
      presenter = described_class.new(jobs, nonce: 'snonce')
      html = presenter.render
      script_tags = html.scan(/<script[^>]*>/)
      expect(script_tags).not_to be_empty
      expect(script_tags).to all(include('nonce="snonce"'))
    end

    it 'omits nonce when not supplied' do
      presenter = described_class.new(jobs)
      html = presenter.render
      expect(html.scan(/<script[^>]*>/).join).not_to include('nonce=')
    end
  end
end
