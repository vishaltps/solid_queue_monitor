# frozen_string_literal: true

# Guard against multiple loads of routes file in test environment
SolidQueueMonitor::Engine.routes.draw do
  return if SolidQueueMonitor::Engine.routes.routes.any? { |r| r.name == 'root' }

  root to: 'overview#index'

  get 'chart_data', to: 'overview#chart_data', as: :chart_data

  resources :ready_jobs, only: [:index]
  resources :scheduled_jobs, only: [:index]
  resources :recurring_jobs, only: [:index]
  resources :failed_jobs, only: [:index]
  resources :in_progress_jobs, only: [:index]
  resources :queues, only: [:index]
  get 'queues/:queue_name', to: 'queues#show', as: :queue_details, constraints: { queue_name: /[^\/]+/ }
  resources :workers, only: [:index]
  resources :jobs, only: [:show]

  post 'execute_jobs', to: 'scheduled_jobs#create', as: :execute_jobs
  post 'execute_scheduled_job/:id', to: 'scheduled_jobs#execute', as: :execute_scheduled_job
  post 'reject_jobs', to: 'scheduled_jobs#reject_all', as: :reject_jobs

  post 'retry_failed_job/:id', to: 'failed_jobs#retry', as: :retry_failed_job
  post 'discard_failed_job/:id', to: 'failed_jobs#discard', as: :discard_failed_job
  post 'retry_failed_jobs', to: 'failed_jobs#retry_all', as: :retry_failed_jobs
  post 'discard_failed_jobs', to: 'failed_jobs#discard_all', as: :discard_failed_jobs

  post 'pause_queue', to: 'queues#pause', as: :pause_queue
  post 'resume_queue', to: 'queues#resume', as: :resume_queue

  post 'remove_worker/:id', to: 'workers#remove', as: :remove_worker
  post 'prune_workers', to: 'workers#prune', as: :prune_workers
end
