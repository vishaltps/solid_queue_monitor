# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Recurring Jobs', type: :system do
  before do
    # Create some recurring jobs for testing
    create(:solid_queue_recurring_execution, job_class: 'DailyCleanupJob', schedule: '0 0 * * *', queue_name: 'default')
    create(:solid_queue_recurring_execution, job_class: 'HourlyReportJob', schedule: '0 * * * *', queue_name: 'reporting')
    create(:solid_queue_recurring_execution, job_class: 'WeeklyMaintenanceJob', schedule: '0 0 * * 0', queue_name: 'maintenance')
  end

  describe 'Recurring Jobs list' do
    it 'displays all recurring jobs' do
      visit '/solid_queue/recurring_jobs'

      expect(page).to have_content('Recurring Jobs')
      expect(page).to have_content('DailyCleanupJob')
      expect(page).to have_content('HourlyReportJob')
      expect(page).to have_content('WeeklyMaintenanceJob')

      # Check for schedule display
      expect(page).to have_content('0 0 * * *')
      expect(page).to have_content('0 * * * *')
      expect(page).to have_content('0 0 * * 0')

      # Check for queue names
      expect(page).to have_content('default')
      expect(page).to have_content('reporting')
      expect(page).to have_content('maintenance')
    end

    it 'allows filtering by job class' do
      visit '/solid_queue/recurring_jobs'

      fill_in 'Filter by class name', with: 'Daily'
      # Either press enter or click a button, depending on implementation
      find("input[type='search']").native.send_keys(:return)

      expect(page).to have_content('DailyCleanupJob')
      expect(page).not_to have_content('HourlyReportJob')
      expect(page).not_to have_content('WeeklyMaintenanceJob')
    end

    it 'allows filtering by queue name' do
      visit '/solid_queue/recurring_jobs'

      fill_in 'Filter by queue name', with: 'report'
      find("input[type='search']").native.send_keys(:return)

      expect(page).not_to have_content('DailyCleanupJob')
      expect(page).to have_content('HourlyReportJob')
      expect(page).not_to have_content('WeeklyMaintenanceJob')
    end
  end

  describe 'Job details' do
    it 'shows job details when clicking on a job' do
      visit '/solid_queue/recurring_jobs'

      # Click on a job to view details
      click_on 'DailyCleanupJob'

      # Expect to see job details
      expect(page).to have_content('DailyCleanupJob Details')
      expect(page).to have_content('Schedule: 0 0 * * *')
      expect(page).to have_content('Queue: default')
    end
  end

  describe 'Job actions' do
    it 'allows triggering a job immediately' do
      visit '/solid_queue/recurring_jobs'

      # Find and click the run button for the first job
      within('tr', text: 'DailyCleanupJob') do
        click_button 'Trigger Now'
      end

      # Expect a success message
      expect(page).to have_content('Job has been enqueued')

      # Verify a new job was created in the database
      visit '/solid_queue'
      expect(page).to have_content('DailyCleanupJob')
    end

    it 'allows pausing a job' do
      visit '/solid_queue/recurring_jobs'

      # Find and click the pause button for the first job
      within('tr', text: 'HourlyReportJob') do
        click_button 'Pause'
      end

      # Expect a success message
      expect(page).to have_content('Job has been paused')

      # Verify the job is now paused
      expect(page).to have_content('Paused')
    end

    it 'allows resuming a paused job' do
      # First pause the job
      job = SolidQueue::RecurringExecution.find_by(job_class: 'WeeklyMaintenanceJob')
      job.update(paused: true)

      visit '/solid_queue/recurring_jobs'

      # Verify the job is displayed as paused
      within('tr', text: 'WeeklyMaintenanceJob') do
        expect(page).to have_content('Paused')
      end

      # Find and click the resume button
      within('tr', text: 'WeeklyMaintenanceJob') do
        click_button 'Resume'
      end

      # Expect a success message
      expect(page).to have_content('Job has been resumed')

      # Verify the job is no longer paused
      within('tr', text: 'WeeklyMaintenanceJob') do
        expect(page).not_to have_content('Paused')
      end
    end
  end
end
