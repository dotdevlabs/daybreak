module Api
  class ApplicationController < ActionController::API
    before_action :authenticate_api_token!

    private

    def authenticate_api_token!
      token = request.headers["Authorization"]&.delete_prefix("Bearer ")&.strip
      expected = ENV["DAYBREAK_API_TOKEN"].presence
      unless expected && token.present? &&
             ActiveSupport::SecurityUtils.secure_compare(token, expected)
        render json: { errors: [ { detail: "Unauthorized" } ] },
               status: :unauthorized,
               content_type: "application/vnd.api+json"
      end
    end

    def render_jsonapi(data:, status: :ok)
      render json: { data: data }, status: status,
             content_type: "application/vnd.api+json"
    end

    def render_jsonapi_errors(messages, status:)
      errors = Array(messages).map { |msg| { detail: msg } }
      render json: { errors: errors }, status: status,
             content_type: "application/vnd.api+json"
    end
  end
end
