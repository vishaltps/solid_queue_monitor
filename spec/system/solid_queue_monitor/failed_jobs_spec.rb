# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Failed Jobs', type: :system do
  let!(:failed_job) { create(:solid_queue_job, :failed, class_name: 'ImportJob') }
  let!(:another_failed_job) { create(:solid_queue_job, :failed, class_name: 'EmailJob', queue_name: 'mailers') }

  describe 'Failed Jobs list' do
    it 'displays all failed jobs' do
      visit '/solid_queue/failed_jobs'

      expect(page).to have_content('Failed Jobs')
      expect(page).to have_content('ImportJob')
      expect(page).to have_content('EmailJob')
      expect(page).to have_content('default')
      expect(page).to have_content('mailers')
    end

    it 'allows filtering by class name' do
      visit '/solid_queue/failed_jobs'

      fill_in 'class_name', with: 'Import'
      click_button 'Filter'

      expect(page).to have_content('ImportJob')
      expect(page).not_to have_content('EmailJob')
    end

    it 'allows filtering by queue name' do
      visit '/solid_queue/failed_jobs'

      fill_in 'queue_name', with: 'mailers'
      click_button 'Filter'

      expect(page).to have_content('EmailJob')
      expect(page).not_to have_content('ImportJob')
    end
  end

  describe 'Job actions' do
    it 'shows error details' do
      visit '/solid_queue/failed_jobs'

      expect(page).to have_content('Error')
      expect(page).to have_content('Something went wrong')
    end
  end

  describe 'Authentication' do
    before do
      # Enable authentication for this test
      allow(SolidQueueMonitor).to receive(:authentication_enabled).and_return(true)
      allow(SolidQueueMonitor).to receive(:username).and_return('admin')
      allow(SolidQueueMonitor).to receive(:password).and_return('password')
    end

    it 'requires authentication when enabled' do
      visit '/solid_queue/failed_jobs'

      # We should see a basic auth dialog, which Capybara can't interact with directly
      # But we can check if we're being redirected or getting a 401
      expect(page).to have_current_path('/solid_queue/failed_jobs')
      expect(page).not_to have_content('Failed Jobs')

      # Now let's authenticate properly
      page.driver.browser.authorize('admin', 'password')
      visit '/solid_queue/failed_jobs'

      # Now we should see the content
      expect(page).to have_content('Failed Jobs')
    end
  end
end
