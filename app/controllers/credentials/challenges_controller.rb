class Credentials::ChallengesController < ApplicationController
  def create
    options = WebAuthn::Credential.options_for_create(
      user: { id: current_user.webauthn_id, name: current_user.email_address },
      exclude: current_user.credentials.map { |c| { id: c.external_id, type: "public-key" } }
    )
    session[:webauthn_challenge] = options.challenge
    render json: options
  end
end
