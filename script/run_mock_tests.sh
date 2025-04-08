#!/bin/bash

# This script runs only the mock-based tests without requiring Rails
# It runs the tests that have been converted to use our mock objects

echo "Running mock-based tests..."

# Run the specified tests using spec_helper instead of rails_helper
bundle exec rspec \
  --options .rspec.mock \
  spec/models/solid_queue/job_spec.rb \
  spec/services/solid_queue_monitor/authentication_service_spec.rb \
  spec/system/solid_queue_monitor/authentication_spec.rb \
  spec/controllers/solid_queue_monitor/application_controller_spec.rb \
  spec/system/solid_queue_monitor/queues_spec.rb

# Check the exit status
if [ $? -eq 0 ]; then
  echo "All mock-based tests passed!"
  exit 0
else
  echo "Some tests failed. Please check the output above."
  exit 1
fi 