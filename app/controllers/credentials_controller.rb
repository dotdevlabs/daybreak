class CredentialsController < ApplicationController
  before_action :set_credential, only: %i[update destroy]

  def index
    @credentials = current_user.credentials.order(created_at: :asc)
  end

  def create
    webauthn_credential = WebAuthn::Credential.from_create(params.require(:credential))
    webauthn_credential.verify(session.delete(:webauthn_challenge))

    current_user.credentials.create!(
      external_id: webauthn_credential.id,
      public_key:  webauthn_credential.public_key,
      sign_count:  webauthn_credential.sign_count,
      nickname:    params[:nickname].presence || "Passkey"
    )
    redirect_to credentials_path, notice: t("auth.passkey.credential_saved")
  rescue WebAuthn::Error => e
    redirect_to credentials_path, alert: e.message
  end

  def update
    @credential.update!(nickname: params[:nickname])
    redirect_to credentials_path, notice: t("auth.passkey.credential_renamed")
  end

  def destroy
    if current_user.credentials.count <= 1
      return redirect_to credentials_path, alert: t("auth.passkey.cannot_remove_last")
    end
    @credential.destroy
    redirect_to credentials_path, notice: t("auth.passkey.credential_removed")
  end

  private

  def set_credential
    @credential = current_user.credentials.find(params[:id])
  end
end
