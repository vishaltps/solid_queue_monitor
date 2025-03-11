Rails.application.routes.draw do
  mount SolidQueueMonitor::Engine => "/queue"
end