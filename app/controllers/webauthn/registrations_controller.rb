class Webauthn::RegistrationsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { head :too_many_requests }

  def create
    user = User.find_by(id: session[:pending_user_id])
    return render json: { error: "session_expired" }, status: :unprocessable_entity unless user

    webauthn_credential = WebAuthn::Credential.from_create(params.require(:credential))
    webauthn_credential.verify(session.delete(:webauthn_challenge))

    user.credentials.create!(
      external_id: webauthn_credential.id,
      public_key:  webauthn_credential.public_key,
      sign_count:  webauthn_credential.sign_count,
      nickname:    "Passkey"
    )

    EmailVerificationsMailer.verify(user).deliver_later
    render json: { step: "check_email", email: user.email_address }
  rescue WebAuthn::Error => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end
