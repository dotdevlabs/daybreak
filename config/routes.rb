Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  root "dashboard#show"

  resource :user_preference, only: [ :update ]

  namespace :dashboard do
    resources :action_item_completions, only: [ :create ]
  end

  namespace :api do
    resource :status, only: [ :show ], controller: :status
    resources :tokens, only: [ :create ]
    resources :catalog, only: [ :index ]
    resources :widgets, only: [ :create ]
    resources :events, only: [ :index ]
    namespace :agent do
      resources :registrations, only: [ :create ]
    end
  end
end
