class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { head :too_many_requests }

  def create
    email = params[:email_address].to_s.strip.downcase
    existing = User.find_by(email_address: email)

    if existing&.verified?
      return render json: { error: t("auth.register.already_registered") }, status: :conflict
    end

    user = existing || User.new(email_address: email)
    unless user.persisted? || user.save
      return render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end

    session[:pending_user_id] = user.id
    render json: { step: "method" }
  end
end
