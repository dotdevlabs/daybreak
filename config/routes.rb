Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  root "dashboard#show"

  # Session: create is the no-JS degraded path for sign-in (email in body, never GET)
  resource :session, only: %i[create destroy]

  # Email-first registration (step 1: creates pending user)
  resource :registration, only: %i[create]

  # Email verification (clicking the link in the email)
  resources :email_verifications, only: %i[show], param: :token

  # Re-send verification email for a pending user
  namespace :email_verification do
    resource :resend, only: %i[create]
  end

  # WebAuthn passkey registration ceremony (unauthenticated)
  namespace :webauthn do
    resource :registration, only: %i[create] do
      resource :challenge, only: %i[create], module: :registration
    end
    resource :authentication, only: %i[create] do
      resource :challenge, only: %i[create], module: :authentication
    end
  end

  # Passkey management (requires authentication)
  resources :credentials, only: %i[index create update destroy]
  post "credentials/challenge", to: "credentials/challenges#create", as: :credentials_challenge

  resource :user_preference, only: %i[update]

  namespace :dashboard do
    resources :action_item_completions, only: %i[create]
  end

  namespace :api do
    resource :status, only: %i[show], controller: :status
    resources :tokens,  only: %i[create]
    resources :catalog, only: %i[index]
    resources :widgets, only: %i[create]
    resources :events,  only: %i[index ]
    namespace :agent do
      resources :registrations, only: %i[create]
    end
  end
end
