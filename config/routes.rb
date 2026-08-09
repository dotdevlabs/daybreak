Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "dashboard#show"

  namespace :dashboard do
    resources :action_item_completions, only: [ :create ]
  end

  namespace :api do
    resources :widgets, only: [ :create ]
    resources :events, only: [ :index ]
    namespace :agent do
      resources :registrations, only: [ :create ]
    end
  end
end
