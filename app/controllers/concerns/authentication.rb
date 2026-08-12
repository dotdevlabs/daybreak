module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?, :current_user
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private

  def authenticated?
    resume_session
  end

  def current_user
    Current.user
  end

  def resume_session
    return true if Current.session

    session_record = cookies.signed[:session_id] && Session.find_by(id: cookies.signed[:session_id])
    if session_record
      Current.session = session_record
      true
    else
      cookies.delete(:session_id)
      false
    end
  end

  def require_authentication
    resume_session || request_authentication
  end

  def request_authentication
    redirect_to root_path
  end

  def start_new_session_for(user)
    session_record = user.sessions.create!(
      user_agent: request.user_agent,
      ip_address: request.remote_ip
    )
    Current.session = session_record
    cookies.signed.permanent[:session_id] = {
      value: session_record.id,
      httponly: true,
      same_site: :lax
    }
  end

  def terminate_session
    Current.session&.destroy
    cookies.delete(:session_id)
  end
end
