module Api
  class WidgetsController < Api::ApplicationController
    def create
      raw = JSON.parse(request.body.read) rescue {}
      message = WidgetMessage.new(type: raw["type"], data: raw["data"])

      if message.invalid?
        return render json: { errors: message.errors.full_messages },
                      status: :unprocessable_entity
      end

      briefing = DailyBriefing.find_or_initialize_by(date: Date.current)
      message.apply_to(briefing)

      if briefing.save
        render json: { status: "ok", widget: message.type, date: briefing.date.iso8601 }
      else
        render json: { errors: briefing.errors.full_messages },
               status: :unprocessable_entity
      end
    end
  end
end
