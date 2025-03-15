Rails.application.routes.draw do
  mount SolidQueueMonitor::Engine => "/solid_queue"
end