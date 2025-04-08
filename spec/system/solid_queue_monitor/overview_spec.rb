# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'SolidQueueMonitor Dashboard', type: :system do
  before do
    # Create some test data
    create_list(:solid_queue_job, 3, :ready)
    create_list(:solid_queue_job, 2, :scheduled)
    create_list(:solid_queue_job, 1, :failed)
    create_list(:solid_queue_job, 1, :in_progress)
    create_list(:solid_queue_recurring_execution, 2)
  end

  describe 'Overview page' do
    it 'displays a summary of jobs' do
      visit '/solid_queue'

      # Check the title
      expect(page).to have_content('Solid Queue Monitor')

      # Check the summary stats
      expect(page).to have_content('Total Jobs')

      # Verify we can see job counts
      expect(page).to have_content(/Ready Jobs.*3/m)
      expect(page).to have_content(/Scheduled Jobs.*2/m)
      expect(page).to have_content(/Failed Jobs.*1/m)
      expect(page).to have_content(/In Progress Jobs.*1/m)
      expect(page).to have_content(/Recurring Jobs.*2/m)
    end

    it 'has links to other pages' do
      visit '/solid_queue'

      expect(page).to have_link('Ready Jobs')
      expect(page).to have_link('Scheduled Jobs')
      expect(page).to have_link('Failed Jobs')
      expect(page).to have_link('In Progress Jobs')
      expect(page).to have_link('Recurring Jobs')
    end

    it 'shows recent jobs' do
      visit '/solid_queue'

      expect(page).to have_content('Recent Jobs')
      expect(page).to have_content('TestJob')
      expect(page).to have_content('default') # queue name
    end
  end

  describe 'Navigation' do
    it 'allows navigation to other pages' do
      visit '/solid_queue'

      click_link 'Failed Jobs'
      expect(page).to have_current_path('/solid_queue/failed_jobs')
      expect(page).to have_content('Failed Jobs')

      click_link 'Ready Jobs'
      expect(page).to have_current_path('/solid_queue/ready_jobs')
      expect(page).to have_content('Ready Jobs')
    end
  end
end
