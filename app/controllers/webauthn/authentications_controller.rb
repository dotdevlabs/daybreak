class Webauthn::AuthenticationsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { head :too_many_requests }

  def create
    user = User.find_by(id: session[:webauthn_user_id])
    return render json: { error: "session_expired" }, status: :unprocessable_entity unless user

    webauthn_credential = WebAuthn::Credential.from_get(params.require(:credential))
    stored_credential   = user.credentials.find_by!(external_id: webauthn_credential.id)

    webauthn_credential.verify(
      session.delete(:webauthn_challenge),
      public_key:  stored_credential.public_key,
      sign_count:  stored_credential.sign_count
    )
    stored_credential.update!(sign_count: webauthn_credential.sign_count)
    session.delete(:webauthn_user_id)

    if user.verified?
      start_new_session_for(user)
      render json: { redirect_url: root_path }
    else
      render json: {
        error:   "not_verified",
        message: t("auth.email_verification.required"),
        email:   user.email_address
      }, status: :forbidden
    end
  rescue WebAuthn::Error, ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end
