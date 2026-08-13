class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[create]

  # No-JS degraded path: WebAuthn sign-in requires JavaScript.
  # Email arrives in request body (never in URL query string), then redirect gracefully.
  def create
    redirect_to root_path, alert: t("auth.login.javascript_required")
  end

  def destroy
    terminate_session
    redirect_to root_path, status: :see_other
  end
end
