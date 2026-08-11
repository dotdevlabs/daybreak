module Api
  class TokensController < Api::ApplicationController
    skip_before_action :authenticate_api_token!

    def create
      api_token = ApiToken.new
      if api_token.save
        render_jsonapi(
          data: {
            type: "api_tokens",
            id: api_token.id.to_s,
            attributes: { token: api_token.token }
          },
          status: :created
        )
      else
        render_jsonapi_errors(api_token.errors.full_messages, status: :unprocessable_entity)
      end
    end
  end
end
