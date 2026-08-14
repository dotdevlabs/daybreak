module Api
  class ApplicationController < ActionController::API
    before_action :authenticate_api_token!

    private

    def authenticate_api_token!
      bearer = request.headers["Authorization"]&.delete_prefix("Bearer ")&.strip
      unless bearer.present?
        return render_jsonapi_errors([ "Unauthorized" ], status: :unauthorized)
      end

      token = ApiToken.includes(:account).find_by(token: bearer)
      unless token&.account
        return render_jsonapi_errors([ "Unauthorized" ], status: :unauthorized)
      end

      Current.account = token.account
    end

    def render_jsonapi(data:, status: :ok, links: nil, meta: nil)
      body = { data: data }
      body[:links] = links if links
      body[:meta]  = meta  if meta
      render json: body, status: status, content_type: "application/vnd.api+json"
    end

    def render_jsonapi_errors(messages, status:)
      errors = Array(messages).map { |msg| { detail: msg } }
      render json: { errors: errors }, status: status,
             content_type: "application/vnd.api+json"
    end
  end
end
