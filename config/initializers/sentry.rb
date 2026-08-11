return unless ENV["SENTRY_DSN"].present?

Sentry.init do |config|
  config.dsn                = ENV["SENTRY_DSN"]
  config.environment        = Rails.env.to_s
  config.release            = ENV["APP_SHA"]
  config.send_default_pii   = false
  config.traces_sample_rate = 0.1

  config.before_send = lambda do |event, _hint|
    if (req = event.request)
      req.headers&.reject! { |k, _v| k.match?(/\A(Authorization|Cookie|X-Auth|X-Api-Key)\z/i) }
      req.cookies = {}
    end
    event
  end
end
