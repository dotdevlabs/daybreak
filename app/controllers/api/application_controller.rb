module Api
  class ApplicationController < ActionController::API
    before_action :authenticate_api_token!

    private

    def authenticate_api_token!
      bearer = request.headers["Authorization"]&.delete_prefix("Bearer ")&.strip
      unless bearer.present? && valid_api_token?(bearer)
        render json: { errors: [ { detail: "Unauthorized" } ] },
               status: :unauthorized,
               content_type: "application/vnd.api+json"
      end
    end

    def valid_api_token?(bearer)
      return true if ApiToken.exists?(token: bearer)
      expected = ENV["DAYBREAK_API_TOKEN"].presence
      expected && ActiveSupport::SecurityUtils.secure_compare(bearer, expected)
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
