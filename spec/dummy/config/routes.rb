# frozen_string_literal: true

Rails.application.routes.draw do
  # Mount the SolidQueueMonitor engine
  mount SolidQueueMonitor::Engine => '/solid_queue'

  # Add a root route for convenience
  root to: redirect('/solid_queue')
end
