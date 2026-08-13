class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { head :too_many_requests }

  def create
    email = params[:email_address].to_s.strip.downcase
    existing = User.find_by(email_address: email)

    if existing&.verified?
      respond_to do |format|
        format.json { render json: { error: t("auth.register.already_registered") }, status: :conflict }
        format.html { redirect_to root_path, alert: t("auth.register.already_registered") }
      end
      return
    end

    user = existing || User.new(email_address: email)
    unless user.persisted? || user.save
      respond_to do |format|
        format.json { render json: { errors: user.errors.full_messages }, status: :unprocessable_entity }
        format.html { redirect_to root_path, alert: user.errors.full_messages.join(", ") }
      end
      return
    end

    session[:pending_user_id] = user.id
    respond_to do |format|
      format.json { render json: { step: "method" } }
      format.html { redirect_to root_path }
    end
  end
end
