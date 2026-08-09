module Api
  class ApplicationController < ActionController::API
    before_action :authenticate_api_token!

    private

    def authenticate_api_token!
      token = request.headers["Authorization"]&.delete_prefix("Bearer ")&.strip
      expected = ENV["DAYBREAK_API_TOKEN"].presence
      unless expected && token.present? &&
             ActiveSupport::SecurityUtils.secure_compare(token, expected)
        render json: { error: "Unauthorized" }, status: :unauthorized
      end
    end
  end
end
