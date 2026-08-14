module Api
  class TokensController < Api::ApplicationController
    include ActionController::Cookies

    skip_before_action :authenticate_api_token!
    before_action :require_browser_session!

    def create
      api_token = Current.user.account.api_tokens.create!
      render_jsonapi(
        data: {
          type: "api_tokens",
          id: api_token.id.to_s,
          attributes: { token: api_token.token },
          links: { self: "/api/tokens/#{api_token.id}" }
        },
        status: :created
      )
    end

    private

    def require_browser_session!
      session_record = cookies.signed[:session_id] &&
                       Session.find_by(id: cookies.signed[:session_id])
      if session_record
        Current.session = session_record
      else
        render_jsonapi_errors([ "Unauthorized" ], status: :unauthorized)
      end
    end
  end
end
