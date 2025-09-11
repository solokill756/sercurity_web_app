Rails.application.routes.draw do
  root "events#index"

  resources :sessions, only: %i(new create destroy)
  resources :users, only: %i(show edit update)
  resources :events do
    resources :comments, only: %i(create destroy)
  end
  
  # XSS Demo routes
  get '/xss_demo', to: 'xss_demo#index'
  
  # Stored XSS
  get '/xss_demo/stored', to: 'xss_demo#stored_xss', as: 'stored_xss'
  post '/xss_demo/stored', to: 'xss_demo#create_stored_xss'
  
  # Reflected XSS
  get '/xss_demo/reflected', to: 'xss_demo#reflected_xss', as: 'reflected_xss'
  
  # DOM-based XSS
  get '/xss_demo/dom_based', to: 'xss_demo#dom_based_xss', as: 'dom_based_xss'
  
  # Safe versions
  get '/xss_demo/safe_stored', to: 'xss_demo#safe_stored_xss', as: 'safe_stored_xss'
  post '/xss_demo/safe_stored', to: 'xss_demo#create_safe_stored_xss'
  get '/xss_demo/safe_reflected', to: 'xss_demo#safe_reflected_xss', as: 'safe_reflected_xss'
  
  # Utility
  delete '/xss_demo/clear_comments', to: 'xss_demo#clear_comments', as: 'clear_comments'
end
