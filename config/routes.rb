Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions:      'users/sessions'
  }

  # Public-facing creator profile + video pages
  scope '/:username', as: :creator do
    get  '/',        to: 'profiles#show',   as: :profile
    get  '/videos',  to: 'profiles#videos', as: :videos
    get  '/videos/:id', to: 'videos#show',  as: :video
    post '/subscribe', to: 'subscriptions#create', as: :subscribe
  end

  # Invitation acceptance (public, token-based)
  resources :invitations, only: [:show] do
    member { post :accept }
  end

  # Creator dashboard
  namespace :creator do
    root to: 'dashboard#index'
    resources :videos do
      member { patch :publish; patch :archive }
    end
    resources :invitations, only: [:index, :new, :create, :destroy] do
      member { patch :revoke }
    end
    resources :plans
    resources :subscriptions, only: [:index] do
      member { delete :revoke }
    end
    get  :analytics, to: 'analytics#index'
    resources :payouts, only: [:index]
  end

  # Subscriber dashboard
  namespace :subscriber do
    root to: 'dashboard#index'
    resources :subscriptions, only: [:index, :destroy]
    resources :feed, only: [:index]
  end

  # Stripe webhooks
  mount Pay::Engine, at: "/pay", as: "pay_engine"

  root to: 'home#index'

  # Health check
  get '/up', to: 'rails/health#show', as: :rails_health_check
end
