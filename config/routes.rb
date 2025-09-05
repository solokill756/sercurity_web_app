Rails.application.routes.draw do
  root "events#index"

  resources :sessions, only: %i(new create destroy)
  resources :users, only: %i(show update)
  resources :events do
    resources :comments, only: %i(create destroy)
  end
end
