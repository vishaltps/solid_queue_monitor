SolidQueueMonitor::Engine.routes.draw do
  root to: 'monitor#index'
  get '/scheduled_jobs', to: 'monitor#scheduled_jobs'
  get '/recurring_jobs', to: 'monitor#recurring_jobs'
  get '/failed_jobs', to: 'monitor#failed_jobs'
  post '/execute_job', to: 'monitor#execute_job'
end