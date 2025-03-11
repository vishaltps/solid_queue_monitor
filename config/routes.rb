SolidQueueMonitor::Engine.routes.draw do
  root to: 'monitor#index'
  post 'execute_job', to: 'monitor#execute_job'
end