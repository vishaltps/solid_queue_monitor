# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'No unbounded pluck calls in controllers' do
  root = File.expand_path('../../..', __dir__)
  controller_files = Dir[File.join(root, 'app', 'controllers', '**', '*.rb')]

  raise "No controller files found from #{root}" if controller_files.empty?

  controller_files.each do |file|
    relative = file.sub("#{root}/", '')

    it "#{relative} does not use unbounded pluck for subquery filters" do
      content = File.read(file)

      # Catch patterns like:
      #   SolidQueue::FailedExecution.pluck(:job_id)
      #   SolidQueue::Job.where(...).pluck(:id)
      # But NOT bounded plucks like:
      #   SolidQueue::FailedExecution.where(job_id: job_ids).pluck(:job_id)
      # The distinction: unbounded plucks are used to build WHERE IN arrays for filtering.
      # We detect lines that assign pluck results to variables used in .where(id: ...) patterns.
      pluck_filter_lines = content.lines.select do |line|
        line.match?(/=\s*SolidQueue::\w+(\.\w+\(.*\))*\.pluck\(:(?:job_)?id\)/) &&
          !line.match?(/\.where\(job_id:/)
      end

      expect(pluck_filter_lines).to be_empty,
        "Found unbounded pluck calls used for filtering in #{relative}:\n" \
        "#{pluck_filter_lines.map(&:strip).join("\n")}\n" \
        "Use .select(:job_id) or .select(:id) for subqueries instead."
    end
  end
end
