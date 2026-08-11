module Api
  class StatusController < Api::ApplicationController
    def show
      render_jsonapi(data: AppStatus.as_jsonapi)
    end
  end
end
