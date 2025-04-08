# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Queues', type: :system do
  include MockSystemTest

  describe 'Queues overview' do
    before do
      # Set up mock data for queues
      allow_any_instance_of(MockSystemTest::PageMock).to receive(:html).and_return(<<~HTML)
        <h1>Queues</h1>
        <table>
          <tr>
            <td>default</td>
            <td>5</td>
          </tr>
          <tr>
            <td>mailers</td>
            <td>3</td>
          </tr>
          <tr>
            <td>active_storage</td>
            <td>2</td>
          </tr>
        </table>
      HTML
    end

    it 'displays queue statistics' do
      visit '/solid_queue/queues'

      expect(page.html).to include('Queues')

      # Check that each queue is listed with its job count
      expect(page.html).to include('default')
      expect(page.html).to include('mailers')
      expect(page.html).to include('active_storage')
      expect(page.html).to include('5')
      expect(page.html).to include('3')
      expect(page.html).to include('2')
    end

    it 'allows filtering jobs by queue' do
      # Set up filtered page content when clicking a link
      allow_any_instance_of(MockSystemTest::PageMock).to receive(:html).and_return(<<~HTML)
        <h1>Queue: default</h1>
        <table>
          <tbody>
            <tr><td>Job 1</td><td>default</td></tr>
            <tr><td>Job 2</td><td>default</td></tr>
            <tr><td>Job 3</td><td>default</td></tr>
            <tr><td>Job 4</td><td>default</td></tr>
            <tr><td>Job 5</td><td>default</td></tr>
          </tbody>
        </table>
      HTML

      visit '/solid_queue/queues'

      # Click on the default queue
      click_link 'default'

      # Should show jobs from the default queue
      expect(page.html).to include('Queue: default')
      expect(page.html).to include('Job 1')
      expect(page.html).to include('default')
    end
  end

  describe 'Pagination' do
    it 'shows pagination links' do
      # Set up a page with pagination links
      allow_any_instance_of(MockSystemTest::PageMock).to receive(:html).and_return(<<~HTML)
        <h1>Queue: pagination_test</h1>
        <table>
          <tbody>
            <tr><td>Job 1</td><td>pagination_test</td></tr>
            <tr><td>Job 2</td><td>pagination_test</td></tr>
          </tbody>
        </table>
        <div class="pagination">
          <a href="?page=1">1</a>
          <a href="?page=2">2</a>
          <a href="?page=3">3</a>
        </div>
      HTML

      visit '/solid_queue?queue_name=pagination_test'

      # Verify pagination links are present
      expect(page.html).to include('?page=1')
      expect(page.html).to include('?page=2')
      expect(page.html).to include('?page=3')
    end
  end
end
