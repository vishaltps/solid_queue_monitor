SolidQueueMonitor::Engine.routes.draw do
  root to: 'monitor#index'
  get '/scheduled_jobs', to: 'monitor#scheduled_jobs'
  # get '/recurring_jobs', to: 'monitor#recurring_jobs'
  get '/failed_jobs', to: 'monitor#failed_jobs'
  get '/queues', to: 'monitor#queues'
  get '/ready_jobs', to: 'monitor#ready_jobs'
  post 'execute_jobs', to: 'monitor#execute_jobs', as: :execute_jobs
end