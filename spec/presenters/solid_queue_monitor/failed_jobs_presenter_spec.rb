# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidQueueMonitor::FailedJobsPresenter do
  let(:job) { create(:solid_queue_job) }
  let(:failed_execution) { create(:solid_queue_failed_execution, job: job) }
  let(:jobs) { [failed_execution] }

  describe 'CSP nonce propagation' do
    it 'stamps nonce on its inline <script>' do
      presenter = described_class.new(jobs, nonce: 'pnonce')
      html = presenter.render
      script_tags = html.scan(/<script[^>]*>/)
      expect(script_tags).not_to be_empty
      expect(script_tags).to all(include('nonce="pnonce"'))
    end

    it 'omits nonce when not supplied' do
      presenter = described_class.new(jobs)
      html = presenter.render
      expect(html.scan(/<script[^>]*>/).join).not_to include('nonce=')
    end
  end
end
