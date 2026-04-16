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
        scripts.each { |tag| expect(tag).to include('nonce="abc123"') }
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
        scripts.each { |tag| expect(tag).not_to include('nonce=') }
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
        flash_script = html[/<script[^>]*>[^<]*flash-message[\s\S]*?<\/script>/]
        expect(flash_script).to include('nonce="xyz"')
      end
    end
  end
end

RSpec.describe SolidQueueMonitor::FailedJobsPresenter do
  let(:job) { create(:solid_queue_job) }
  let(:failed_execution) { create(:solid_queue_failed_execution, job: job) }
  let(:jobs) { [failed_execution] }

  it 'stamps nonce on its inline <script>', skip: 'Route loading issues in test environment' do
    presenter = described_class.new(jobs, nonce: 'pnonce')
    html = presenter.render
    script_tags = html.scan(/<script[^>]*>/)
    expect(script_tags).not_to be_empty
    script_tags.each { |tag| expect(tag).to include('nonce="pnonce"') }
  end

  it 'omits nonce when not supplied', skip: 'Route loading issues in test environment' do
    presenter = described_class.new(jobs)
    html = presenter.render
    html.scan(/<script[^>]*>/).each { |tag| expect(tag).not_to include('nonce=') }
  end
end

RSpec.describe SolidQueueMonitor::ScheduledJobsPresenter do
  let(:job) { create(:solid_queue_job) }
  let(:scheduled_execution) { create(:solid_queue_scheduled_execution, job: job) }
  let(:jobs) { [scheduled_execution] }

  it 'stamps nonce on its inline <script>', skip: 'Route loading issues in test environment' do
    presenter = described_class.new(jobs, nonce: 'snonce')
    html = presenter.render
    script_tags = html.scan(/<script[^>]*>/)
    expect(script_tags).not_to be_empty
    script_tags.each { |tag| expect(tag).to include('nonce="snonce"') }
  end

  it 'omits nonce when not supplied', skip: 'Route loading issues in test environment' do
    presenter = described_class.new(jobs)
    html = presenter.render
    html.scan(/<script[^>]*>/).each { |tag| expect(tag).not_to include('nonce=') }
  end
end

RSpec.describe SolidQueueMonitor::JobDetailsPresenter do
  let(:job) { create(:solid_queue_job) }

  it 'stamps nonce on all inline <script> tags', skip: 'Route loading issues in test environment' do
    presenter = described_class.new(job, nonce: 'jnonce')
    html = presenter.render
    script_tags = html.scan(/<script[^>]*>/)
    expect(script_tags).not_to be_empty
    script_tags.each { |tag| expect(tag).to include('nonce="jnonce"') }
  end

  it 'omits nonce when not supplied', skip: 'Route loading issues in test environment' do
    presenter = described_class.new(job)
    html = presenter.render
    html.scan(/<script[^>]*>/).each { |tag| expect(tag).not_to include('nonce=') }
  end
end
