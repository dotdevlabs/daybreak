class OutboundMessage
  attr_reader :type, :action, :data, :account

  def initialize(type:, action:, data:, account:)
    @type = type
    @action = action
    @data = data
    @account = account
  end

  def as_json(*)
    { "type" => type, "action" => action, "data" => data }
  end

  def deliver
    pushed = AgentPushRegistry.instance.broadcast_to(account.id, as_json.to_json)
    unless pushed
      endpoint = account.agent_endpoints.last
      deliver_to(endpoint) if endpoint
    end
    true
  end

  private

  def deliver_to(endpoint)
    uri = URI.parse(endpoint.callback_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = 5
    http.read_timeout = 5
    req = Net::HTTP::Post.new(uri.request_uri)
    req["Content-Type"] = "application/json"
    req.body = as_json.to_json
    http.request(req)
  rescue StandardError => e
    Rails.logger.error "OutboundMessage callback delivery failed: #{e.message}"
  end
end
