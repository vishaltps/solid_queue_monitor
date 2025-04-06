# frozen_string_literal: true

Rails.application.routes.draw do
  mount SolidQueueMonitor::Engine => '/solid_queue'
end
