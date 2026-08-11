module Api
  class WidgetsController < Api::ApplicationController
    def create
      raw = JSON.parse(request.body.read)
      attrs = raw.dig("data", "attributes") || {}
      message = WidgetMessage.new(type: attrs["widget_type"], data: attrs["data"])

      if message.invalid?
        return render_jsonapi_errors(message.errors.full_messages,
                                     status: :unprocessable_entity)
      end

      briefing = DailyBriefing.find_or_initialize_by(date: Date.current)
      message.apply_to(briefing)

      if briefing.save
        render_jsonapi(
          data: {
            type: "widget_messages",
            id: briefing.date.iso8601,
            attributes: { widget_type: message.type, date: briefing.date.iso8601 },
            links: { self: "/api/widgets/#{briefing.date.iso8601}" }
          },
          status: :created
        )
      else
        render_jsonapi_errors(briefing.errors.full_messages, status: :unprocessable_entity)
      end
    rescue JSON::ParserError
      render_jsonapi_errors([ "Request body must be valid JSON" ], status: :unprocessable_entity)
    end
  end
end
