# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/mock_rails_routes'

RSpec.describe SolidQueueMonitor::HtmlGenerator do
  before do
    # Mock the StylesheetGenerator
    allow_any_instance_of(SolidQueueMonitor::StylesheetGenerator).to receive(:generate).and_return('/* CSS styles */')
  end

  describe '#generate' do
    it 'generates HTML with the title and content' do
      generator = SolidQueueMonitor::HtmlGenerator.new(
        title: 'Test Title',
        content: 'Test Content'
      )

      html = generator.generate
      expect(html).to include('Test Title')
      expect(html).to include('Test Content')
    end

    it 'includes flash message when provided' do
      generator = SolidQueueMonitor::HtmlGenerator.new(
        title: 'Test Title',
        content: 'Test Content',
        message: 'Operation successful',
        message_type: 'success'
      )

      html = generator.generate
      expect(html).to include('Operation successful')
      expect(html).to include('message-success')
    end
  end
end
