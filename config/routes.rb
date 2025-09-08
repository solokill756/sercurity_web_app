Rails.application.routes.draw do
  root "events#index"

  resources :sessions, only: %i(new create destroy)
  resources :users, only: %i(show update)
  resources :events do
    resources :comments, only: %i(create destroy)
  end

  # SQL Injection Demo Routes
  get 'sqli/classic', to: 'sqli#classic_demo', as: 'sqli_classic_demo'
  get 'sqli/error-based', to: 'sqli#error_based_demo', as: 'sqli_error_based_demo'
  get 'sqli/error-raw', to: 'sqli#error_raw_demo', as: 'sqli_error_raw_demo'
  get 'sqli/union', to: 'sqli#union_demo', as: 'sqli_union_demo'
  get 'sqli/blind', to: 'sqli#blind_demo', as: 'sqli_blind_demo'
  get 'sqli/time-based', to: 'sqli#time_based_demo', as: 'sqli_time_based_demo'
end
