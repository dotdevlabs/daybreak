module Api
  module Agent
    class RegistrationsController < Api::ApplicationController
      def create
        raw = JSON.parse(request.body.read)
        attrs = raw.dig("data", "attributes") || {}
        @endpoint = Current.account.agent_endpoints.build(callback_url: attrs["callback_url"])

        if @endpoint.save
          render_jsonapi(
            data: {
              type: "agent_registrations",
              id: @endpoint.id.to_s,
              attributes: { callback_url: @endpoint.callback_url },
              links: { self: "/api/agent/registrations/#{@endpoint.id}" }
            },
            status: :created
          )
        else
          render_jsonapi_errors(@endpoint.errors.full_messages,
                                status: :unprocessable_entity)
        end
      rescue JSON::ParserError
        render_jsonapi_errors([ "Request body must be valid JSON" ],
                              status: :unprocessable_entity)
      end
    end
  end
end
