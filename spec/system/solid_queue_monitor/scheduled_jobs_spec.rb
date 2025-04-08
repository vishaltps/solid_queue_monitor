# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Scheduled Jobs', type: :system do
  before do
    # Create some scheduled jobs for testing
    create(:solid_queue_job, :scheduled, class_name: 'ImportJob', queue_name: 'default',
                                         scheduled_at: 1.day.from_now)
    create(:solid_queue_job, :scheduled, class_name: 'EmailJob', queue_name: 'mailers',
                                         scheduled_at: 2.hours.from_now)
    create(:solid_queue_job, :scheduled, class_name: 'CleanupJob', queue_name: 'maintenance',
                                         scheduled_at: 1.hour.from_now)
    create(:solid_queue_job, :scheduled, class_name: 'ReportJob', queue_name: 'reporting',
                                         scheduled_at: 30.minutes.from_now)
  end

  describe 'Scheduled Jobs list' do
    it 'displays all scheduled jobs' do
      visit '/solid_queue/scheduled_jobs'

      expect(page).to have_content('Scheduled Jobs')
      expect(page).to have_content('ImportJob')
      expect(page).to have_content('EmailJob')
      expect(page).to have_content('CleanupJob')
      expect(page).to have_content('ReportJob')

      # Check for queue names
      expect(page).to have_content('default')
      expect(page).to have_content('mailers')
      expect(page).to have_content('maintenance')
      expect(page).to have_content('reporting')

      # Check for scheduled times (testing general format, not exact times)
      expect(page).to have_content('day')
      expect(page).to have_content('hour')
      expect(page).to have_content('minute')
    end

    it 'sorts jobs by scheduled time' do
      visit '/solid_queue/scheduled_jobs'

      # The jobs should be sorted by scheduled_at, so ReportJob should appear first
      job_elements = all('tr').map(&:text)
      report_index = job_elements.find_index { |text| text.include?('ReportJob') }
      cleanup_index = job_elements.find_index { |text| text.include?('CleanupJob') }
      email_index = job_elements.find_index { |text| text.include?('EmailJob') }
      import_index = job_elements.find_index { |text| text.include?('ImportJob') }

      # Check the order is correct (ignore header row)
      expect(report_index).to be < cleanup_index
      expect(cleanup_index).to be < email_index
      expect(email_index).to be < import_index
    end

    it 'allows filtering by job class' do
      visit '/solid_queue/scheduled_jobs'

      fill_in 'Filter by class name', with: 'Email'
      find("input[type='search']").native.send_keys(:return)

      expect(page).to have_content('EmailJob')
      expect(page).not_to have_content('ImportJob')
      expect(page).not_to have_content('CleanupJob')
      expect(page).not_to have_content('ReportJob')
    end

    it 'allows filtering by queue name' do
      visit '/solid_queue/scheduled_jobs'

      fill_in 'Filter by queue name', with: 'mail'
      find("input[type='search']").native.send_keys(:return)

      expect(page).to have_content('EmailJob')
      expect(page).not_to have_content('ImportJob')
      expect(page).not_to have_content('CleanupJob')
      expect(page).not_to have_content('ReportJob')
    end
  end

  describe 'Job actions' do
    it 'allows running a scheduled job immediately' do
      visit '/solid_queue/scheduled_jobs'

      # Find and click the run now button for EmailJob
      within('tr', text: 'EmailJob') do
        click_button 'Run Now'
      end

      # Expect a success message
      expect(page).to have_content('Job has been moved to ready queue')

      # The job should no longer be in the scheduled jobs list
      expect(page).not_to have_content('EmailJob')

      # It should be moved to ready queue
      visit '/solid_queue/ready_jobs'
      expect(page).to have_content('EmailJob')
    end

    it 'allows discarding a scheduled job' do
      visit '/solid_queue/scheduled_jobs'

      # Find and click the discard button for CleanupJob
      within('tr', text: 'CleanupJob') do
        click_button 'Discard'
      end

      # Confirm in the dialog
      page.driver.browser.switch_to.alert.accept

      # Expect a success message
      expect(page).to have_content('Job has been discarded')

      # The job should no longer be in the list
      expect(page).not_to have_content('CleanupJob')
    end

    it 'allows rescheduling a job' do
      visit '/solid_queue/scheduled_jobs'

      # Find and click the reschedule button for ReportJob
      within('tr', text: 'ReportJob') do
        click_button 'Reschedule'
      end

      # Fill in a new time (1 day from now)
      fill_in 'New scheduled time', with: 1.day.from_now.strftime('%Y-%m-%d %H:%M:%S')
      click_button 'Update'

      # Expect a success message
      expect(page).to have_content('Job has been rescheduled')

      # The job should still be in the list but with an updated time
      expect(page).to have_content('ReportJob')
      expect(page).to have_content('day') # Now showing "1 day" instead of "30 minutes"
    end
  end

  describe 'Pagination' do
    before do
      # Set the jobs per page to a small number for testing
      allow(SolidQueueMonitor).to receive(:jobs_per_page).and_return(2)

      # Add more scheduled jobs to test pagination
      5.times do |i|
        create(:solid_queue_job, :scheduled, class_name: "BatchJob#{i}",
                                             queue_name: 'default', scheduled_at: (i + 1).days.from_now)
      end
    end

    it 'paginates the jobs list' do
      visit '/solid_queue/scheduled_jobs'

      # Should show only the first 2 jobs
      expect(all('tr.job-row').count).to eq(2)

      # Navigate to the next page
      click_on 'Next'

      # Should show the next 2 jobs
      expect(all('tr.job-row').count).to eq(2)

      # Continue to the last page
      click_on 'Next'
      click_on 'Next'
      click_on 'Next'

      # Should show the remaining jobs
      expect(all('tr.job-row').count).to be > 0
      expect(all('tr.job-row').count).to be <= 2
    end
  end
end
