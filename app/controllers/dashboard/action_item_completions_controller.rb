module Dashboard
  class ActionItemCompletionsController < ApplicationController
    def create
      OutboundMessage.new(
        type: "action_items",
        action: "item_completed",
        data: {
          "context" => params[:context],
          "item" => { "text" => params[:text], "priority" => params[:priority], "link" => params[:link] }.compact
        },
        account: Current.user.account
      ).deliver
      head :ok
    end
  end
end
