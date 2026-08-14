module Api
  class EventsController < Api::ApplicationController
    include ActionController::Live

    def index
      response.headers["Content-Type"] = "text/event-stream"
      response.headers["Cache-Control"] = "no-cache"
      response.headers["X-Accel-Buffering"] = "no"

      account_id = Current.account.id
      sse = SSE.new(response.stream, retry: 5000, event: "connected")
      sse.write({ status: "connected" })

      AgentPushRegistry.instance.register(account_id, sse)

      loop do
        sleep 15
        sse.write({ type: "ping" }, event: "ping")
      end
    rescue ActionController::Live::ClientDisconnected, IOError
      # agent disconnected
    ensure
      AgentPushRegistry.instance.unregister(account_id, sse) if defined?(sse) && defined?(account_id)
      response.stream.close
    end
  end
end
