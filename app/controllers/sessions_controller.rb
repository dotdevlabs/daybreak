class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[create]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { head :too_many_requests }

  def create
    user = User.authenticate_by(
      email_address: params[:email_address],
      password: params[:password]
    )
    if user
      start_new_session_for(user)
      redirect_to root_path
    else
      @briefing = DailyBriefing.for_today
      @overlay_mode = :login
      @auth_error = t("auth.login.invalid_credentials")
      render "dashboard/show", status: :unprocessable_entity
    end
  end

  def destroy
    terminate_session
    redirect_to root_path, status: :see_other
  end
end
