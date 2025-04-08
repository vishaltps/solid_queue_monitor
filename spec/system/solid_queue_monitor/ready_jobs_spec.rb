# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Ready Jobs', type: :system do
  before do
    # Create some ready jobs for testing
    create(:solid_queue_job, :ready, class_name: 'ImportJob', queue_name: 'default',
                                     created_at: 10.minutes.ago)
    create(:solid_queue_job, :ready, class_name: 'EmailJob', queue_name: 'mailers',
                                     created_at: 5.minutes.ago)
    create(:solid_queue_job, :ready, class_name: 'ProcessImageJob', queue_name: 'media',
                                     created_at: 2.minutes.ago)
    create(:solid_queue_job, :ready, class_name: 'GenerateReportJob', queue_name: 'reporting',
                                     created_at: 1.minute.ago)
  end

  describe 'Ready Jobs list' do
    it 'displays all ready jobs' do
      visit '/solid_queue/ready_jobs'

      expect(page).to have_content('Ready Jobs')
      expect(page).to have_content('ImportJob')
      expect(page).to have_content('EmailJob')
      expect(page).to have_content('ProcessImageJob')
      expect(page).to have_content('GenerateReportJob')

      # Check for queue names
      expect(page).to have_content('default')
      expect(page).to have_content('mailers')
      expect(page).to have_content('media')
      expect(page).to have_content('reporting')
    end

    it 'sorts jobs by created time by default' do
      visit '/solid_queue/ready_jobs'

      jobs = all('tr.job-row').map { |row| row.text }

      # Verify the most recent job appears first (GenerateReportJob)
      expect(jobs.first).to include('GenerateReportJob')

      # And the oldest job appears last (ImportJob)
      expect(jobs.last).to include('ImportJob')
    end

    it 'allows filtering by job class' do
      visit '/solid_queue/ready_jobs'

      fill_in 'Filter by class name', with: 'Email'
      find("input[type='search']").native.send_keys(:return)

      expect(page).to have_content('EmailJob')
      expect(page).not_to have_content('ImportJob')
      expect(page).not_to have_content('ProcessImageJob')
      expect(page).not_to have_content('GenerateReportJob')
    end

    it 'allows filtering by queue name' do
      visit '/solid_queue/ready_jobs'

      fill_in 'Filter by queue name', with: 'mail'
      find("input[type='search']").native.send_keys(:return)

      expect(page).to have_content('EmailJob')
      expect(page).not_to have_content('ImportJob')
      expect(page).not_to have_content('ProcessImageJob')
      expect(page).not_to have_content('GenerateReportJob')
    end
  end

  describe 'Job details' do
    it 'shows job arguments when expanded' do
      # Create a job with arguments
      create(:solid_queue_job, :ready, class_name: 'JobWithArgs', queue_name: 'default',
                                       arguments: [{ user_id: 123, action: 'sync' }])

      visit '/solid_queue/ready_jobs'

      # Click to expand the job details
      find('tr', text: 'JobWithArgs').click

      # Verify arguments are displayed
      expect(page).to have_content('user_id')
      expect(page).to have_content('123')
      expect(page).to have_content('action')
      expect(page).to have_content('sync')
    end
  end

  describe 'Job actions' do
    it 'allows discarding a ready job' do
      visit '/solid_queue/ready_jobs'

      # Find and click the discard button for ProcessImageJob
      within('tr', text: 'ProcessImageJob') do
        click_button 'Discard'
      end

      # Confirm in the dialog
      page.driver.browser.switch_to.alert.accept

      # Expect a success message
      expect(page).to have_content('Job has been discarded')

      # The job should no longer be in the list
      expect(page).not_to have_content('ProcessImageJob')
    end

    it 'allows scheduling a ready job for later' do
      visit '/solid_queue/ready_jobs'

      # Find and click the schedule button for GenerateReportJob
      within('tr', text: 'GenerateReportJob') do
        click_button 'Schedule'
      end

      # Fill in a scheduled time
      fill_in 'Scheduled time', with: 1.hour.from_now.strftime('%Y-%m-%d %H:%M:%S')
      click_button 'Schedule'

      # Expect a success message
      expect(page).to have_content('Job has been scheduled')

      # The job should no longer be in the ready jobs list
      expect(page).not_to have_content('GenerateReportJob')

      # It should now be in the scheduled jobs list
      visit '/solid_queue/scheduled_jobs'
      expect(page).to have_content('GenerateReportJob')
    end
  end

  describe 'Queue filtering' do
    it 'allows filtering jobs by queue' do
      visit '/solid_queue/ready_jobs'

      # Click on queue filter
      click_on 'Queue: All'
      click_on 'mailers'

      # Should only show jobs from the mailers queue
      expect(page).to have_content('EmailJob')
      expect(page).not_to have_content('ImportJob')
      expect(page).not_to have_content('ProcessImageJob')
      expect(page).not_to have_content('GenerateReportJob')
    end
  end

  describe 'Pagination' do
    before do
      # Set the jobs per page to a small number for testing
      allow(SolidQueueMonitor).to receive(:jobs_per_page).and_return(2)

      # Add more ready jobs to test pagination
      5.times do |i|
        create(:solid_queue_job, :ready, class_name: "BatchJob#{i}",
                                         queue_name: 'default', created_at: (i + 20).minutes.ago)
      end
    end

    it 'paginates the jobs list' do
      visit '/solid_queue/ready_jobs'

      # Should show only the first 2 jobs
      expect(all('tr.job-row').count).to eq(2)

      # Navigate to the next page
      click_on 'Next'

      # Should show the next 2 jobs
      expect(all('tr.job-row').count).to eq(2)

      # Check that we have more pages
      expect(page).to have_content('Next')
    end
  end
end
