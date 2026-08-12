class PasswordsController < ApplicationController
  allow_unauthenticated_access

  def new
  end

  def create
    user = User.find_by(email_address: params[:email_address].to_s.strip.downcase)
    PasswordsMailer.reset(user).deliver_later if user
    redirect_to root_path, notice: t("auth.passwords.email_sent")
  end

  def edit
    @user = User.find_by_password_reset_token!(params[:token])
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to new_password_path, alert: t("auth.passwords.invalid_token")
  end

  def update
    @user = User.find_by_password_reset_token!(params[:token])
    if @user.update(password: params[:password], password_confirmation: params[:password_confirmation])
      redirect_to root_path, notice: t("auth.passwords.password_updated")
    else
      render :edit, status: :unprocessable_entity
    end
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to new_password_path, alert: t("auth.passwords.invalid_token")
  end
end
