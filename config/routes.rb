Rails.application.routes.draw do
  # API routes for chats and messages
  resources :chats, only: [:index, :show, :create] do
    resources :messages, only: [:create]
    member do
      get :usage, to: 'usage#chat_usage'
    end
  end

  # Home route that will serve our simple UI
  root 'chats#index'

  # Health check for monitoring
  get "up" => "rails/health#show", as: :rails_health_check
  
  # Usage monitoring routes
  resources :usage, only: [:index] do
    collection do
      get :daily
      get :monthly
      get :top_chats
    end
  end
  
  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
