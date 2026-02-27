Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions:      'users/sessions'
  }

  # Admin
  namespace :admin do
    root to: 'dashboard#index'
    resources :videos do
      member { patch :publish; patch :unpublish }
    end
    resources :subscribers, only: [:index]
  end

  # Subscriber feed + video player
  resources :videos, only: [:index, :show]

  # Stripe webhooks
  mount Pay::Engine, at: '/pay', as: 'pay_engine'

  # Preview / Pricing / subscribe
  get  '/preview',   to: 'pages#preview',   as: :preview
  get  '/pricing',   to: 'pages#pricing',   as: :pricing
  post '/subscribe', to: 'subscriptions#create', as: :subscribe

  root to: 'pages#home'

  get '/up', to: 'rails/health#show', as: :rails_health_check
end
