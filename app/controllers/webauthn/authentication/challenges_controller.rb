class Webauthn::Authentication::ChallengesController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { head :too_many_requests }

  def create
    user = User.find_by(email_address: params[:email_address].to_s.strip.downcase)

    if user && user.credentials.any?
      options = WebAuthn::Credential.options_for_get(
        allow: user.credentials.map(&:external_id)
      )
      session[:webauthn_challenge] = options.challenge
      session[:webauthn_user_id]   = user.id
      render json: options
    else
      options = WebAuthn::Credential.options_for_get(allow: [])
      render json: options
    end
  end
end
