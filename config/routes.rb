SolidQueueMonitor::Engine.routes.draw do
  root to: 'monitor#index'
  
  get 'ready_jobs', to: 'monitor#ready_jobs', as: 'ready_jobs'
  get 'scheduled_jobs', to: 'monitor#scheduled_jobs', as: 'scheduled_jobs'
  get 'failed_jobs', to: 'monitor#failed_jobs', as: 'failed_jobs'
  get 'recurring_jobs', to: 'monitor#recurring_jobs', as: 'recurring_jobs'
  get 'queues', to: 'monitor#queues', as: 'queues'
  
  post 'execute_jobs', to: 'monitor#execute_jobs', as: 'execute_jobs'
  
  # Failed job actions
  post 'retry_failed_job/:id', to: 'monitor#retry_failed_job', as: 'retry_failed_job'
  post 'discard_failed_job/:id', to: 'monitor#discard_failed_job', as: 'discard_failed_job'
  post 'retry_failed_jobs', to: 'monitor#retry_failed_jobs', as: 'retry_failed_jobs'
  post 'discard_failed_jobs', to: 'monitor#discard_failed_jobs', as: 'discard_failed_jobs'
end