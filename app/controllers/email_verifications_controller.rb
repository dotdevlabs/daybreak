class EmailVerificationsController < ApplicationController
  allow_unauthenticated_access

  def show
    user = User.find_by_token_for!(:email_verification, params[:token])
    user.verify! unless user.verified?
    start_new_session_for(user)
    redirect_to root_path, notice: t("auth.email_verification.success")
  rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound
    redirect_to root_path, alert: t("auth.email_verification.invalid_token")
  end
end
