module Api
  module Agent
    class RegistrationsController < Api::ApplicationController
      def create
        @endpoint = AgentEndpoint.new(callback_url: params[:callback_url])
        if @endpoint.save
          render json: { status: "ok", callback_url: @endpoint.callback_url }
        else
          render json: { errors: @endpoint.errors.full_messages },
                 status: :unprocessable_entity
        end
      end
    end
  end
end
