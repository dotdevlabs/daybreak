class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { head :too_many_requests }

  def create
    @user = User.new(
      email_address: params[:email_address],
      password: params[:password],
      password_confirmation: params[:password_confirmation]
    )
    if @user.save
      start_new_session_for(@user)
      redirect_to root_path
    else
      @briefing = DailyBriefing.for_today
      @overlay_mode = :register
      @auth_errors = @user.errors.full_messages
      render "dashboard/show", status: :unprocessable_entity
    end
  end
end
