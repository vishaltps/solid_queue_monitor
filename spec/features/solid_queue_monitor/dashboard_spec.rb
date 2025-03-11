require 'spec_helper'

RSpec.describe 'Dashboard', type: :feature do
  before do
    page.driver.basic_authorize('admin', 'password123')
  end

  it 'displays the dashboard' do
    visit '/queue'
    expect(page).to have_content('Solid Queue Monitor')
    expect(page).to have_content('Queue Status Overview')
  end

  it 'shows job statistics' do
    visit '/queue'
    expect(page).to have_content('Total Jobs')
    expect(page).to have_content('Scheduled')
    expect(page).to have_content('Failed')
  end

  context 'with scheduled jobs' do
    before do
      create_scheduled_job
    end

    it 'allows executing scheduled jobs' do
      visit '/queue'
      expect(page).to have_button('Execute Now')
      
      click_button 'Execute Now'
      expect(page).to have_content('Job moved to ready queue')
    end
  end

  private

  def create_scheduled_job
    job = SolidQueue::Job.create!(
      class_name: 'TestJob',
      queue_name: 'default'
    )
    SolidQueue::ScheduledExecution.create!(
      job: job,
      queue_name: 'default',
      scheduled_at: 1.hour.from_now
    )
  end
end