# frozen_string_literal: true

require 'spec_helper'

# The arguments filter must build SQL every supported adapter accepts. It used
# PostgreSQL-only syntax (`arguments::text ILIKE`), which MySQL and SQLite
# reject with a syntax error, so every filtered page answered 500 there.
# Run this file against each adapter with DATABASE_URL (see spec_helper.rb).
RSpec.describe 'Arguments filter' do
  def create_job(class_name, arguments)
    create(:solid_queue_job, class_name: class_name, arguments: arguments)
  end

  shared_examples 'an arguments filter' do
    it 'keeps the jobs whose arguments match, ignoring case' do
      get path, params: { arguments: 'WEBCORPEM.NO-IP.INFO' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('MatchingJob')
      expect(response.body).not_to include('OtherJob')
    end

    it 'treats LIKE wildcards in the search term as literal text' do
      get path, params: { arguments: '100%' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('MatchingJob')
      expect(response.body).not_to include('OtherJob')
    end

    it 'does not fail when the parameter is not a string' do
      get "#{path}?arguments[]=webcorpem"

      expect(response).to have_http_status(:ok)
    end
  end

  let(:matching_arguments) { ['Failed to open TCP connection to webcorpem.no-ip.info:20009', '100%'] }
  let(:other_arguments) { ['order 1000', '100 units'] }

  describe 'GET /failed_jobs' do
    let(:path) { '/failed_jobs' }

    before do
      create(:solid_queue_failed_execution, job: create_job('MatchingJob', matching_arguments))
      create(:solid_queue_failed_execution, job: create_job('OtherJob', other_arguments))
    end

    it_behaves_like 'an arguments filter'
  end

  describe 'GET /ready_jobs' do
    let(:path) { '/ready_jobs' }

    before do
      create(:solid_queue_ready_execution, job: create_job('MatchingJob', matching_arguments))
      create(:solid_queue_ready_execution, job: create_job('OtherJob', other_arguments))
    end

    it_behaves_like 'an arguments filter'
  end

  describe 'GET /scheduled_jobs' do
    let(:path) { '/scheduled_jobs' }

    before do
      create(:solid_queue_scheduled_execution, job: create_job('MatchingJob', matching_arguments))
      create(:solid_queue_scheduled_execution, job: create_job('OtherJob', other_arguments))
    end

    it_behaves_like 'an arguments filter'
  end

  describe 'GET /in_progress_jobs' do
    let(:path) { '/in_progress_jobs' }

    before do
      create(:solid_queue_claimed_execution, job: create_job('MatchingJob', matching_arguments))
      create(:solid_queue_claimed_execution, job: create_job('OtherJob', other_arguments))
    end

    it_behaves_like 'an arguments filter'
  end

  describe 'GET /queues/:queue_name' do
    let(:path) { '/queues/default' }

    before do
      create_job('MatchingJob', matching_arguments)
      create_job('OtherJob', other_arguments)
    end

    it_behaves_like 'an arguments filter'
  end

  describe 'GET /recurring_jobs' do
    let(:path) { '/recurring_jobs' }

    before do
      create(:solid_queue_recurring_task, class_name: 'MatchingJob', arguments: matching_arguments)
      create(:solid_queue_recurring_task, class_name: 'OtherJob', arguments: other_arguments)
    end

    it_behaves_like 'an arguments filter'
  end
end
