class EmailVerification::ResendsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 3, within: 5.minutes, only: :create, with: -> { head :too_many_requests }

  def create
    user = User.find_by(id: session[:pending_user_id])
    if user && !user.verified?
      EmailVerificationsMailer.verify(user).deliver_later
    end
    render json: { sent: true }
  end
end
