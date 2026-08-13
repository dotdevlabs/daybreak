WebAuthn.configure do |config|
  config.allowed_origins = [ ENV.fetch("WEBAUTHN_ORIGIN") do
    if Rails.env.production?
      "https://daybreak.cool"
    elsif Rails.env.test?
      "http://www.example.com"
    else
      "http://localhost:3000"
    end
  end ]
  config.rp_name = ENV.fetch("WEBAUTHN_RP_NAME", "Daybreak")
  config.rp_id   = ENV.fetch("WEBAUTHN_RP_ID") do
    if Rails.env.production?
      "daybreak.cool"
    elsif Rails.env.test?
      "www.example.com"
    else
      "localhost"
    end
  end
end
