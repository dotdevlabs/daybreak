class StatusController < ActionController::API
  def show
    render json: { data: AppStatus.as_jsonapi }, content_type: "application/vnd.api+json"
  end
end
