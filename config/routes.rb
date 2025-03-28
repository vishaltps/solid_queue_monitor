SolidQueueMonitor::Engine.routes.draw do
  root to: 'overview#index', as: :root
  
  resources :ready_jobs, only: [:index]
  resources :scheduled_jobs, only: [:index]
  resources :recurring_jobs, only: [:index]
  resources :failed_jobs, only: [:index]
  resources :in_progress_jobs, only: [:index]
  resources :queues, only: [:index]
  
  post 'execute_jobs', to: 'scheduled_jobs#create', as: :execute_jobs
  
  post 'retry_failed_job/:id', to: 'failed_jobs#retry', as: :retry_failed_job
  post 'discard_failed_job/:id', to: 'failed_jobs#discard', as: :discard_failed_job
  post 'retry_failed_jobs', to: 'failed_jobs#retry_all', as: :retry_failed_jobs
  post 'discard_failed_jobs', to: 'failed_jobs#discard_all', as: :discard_failed_jobs
end