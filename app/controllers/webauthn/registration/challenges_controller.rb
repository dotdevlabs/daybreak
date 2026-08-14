class Webauthn::Registration::ChallengesController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { head :too_many_requests }

  def create
    user = User.find_by(id: session[:pending_user_id])
    return render json: { error: "session_expired" }, status: :unprocessable_entity unless user

    options = WebAuthn::Credential.options_for_create(
      user: { id: user.webauthn_id, name: user.email_address, display_name: user.email_address },
      exclude: user.credentials.map(&:external_id)
    )
    session[:webauthn_challenge] = options.challenge
    render json: options
  end
end
