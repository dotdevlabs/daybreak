module Api
  class RegistrationsController < Api::ApplicationController
    skip_before_action :authenticate_api_token!

    def create
      account = Account.create!
      api_token = account.api_tokens.create!
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
  end
end
