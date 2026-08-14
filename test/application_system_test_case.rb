require "test_helper"

# Use localhost so WebAuthn's rpId ("localhost") matches the browser's origin.
# 127.0.0.1 and localhost are different effective domains for WebAuthn validation.
Capybara.server_host = "localhost"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  def sign_in_for_system(user)
    session_record = user.sessions.create!(ip_address: "127.0.0.1", user_agent: "SystemTest")
    env = {
      "action_dispatch.key_generator"             => Rails.application.key_generator,
      "action_dispatch.signed_cookie_salt"        => Rails.application.config.action_dispatch.signed_cookie_salt,
      "action_dispatch.cookies_serializer"        => Rails.application.config.action_dispatch.cookies_serializer,
      "action_dispatch.cookies_digest"            => Rails.application.config.action_dispatch.cookies_digest,
      "action_dispatch.use_cookies_with_metadata" => Rails.application.config.action_dispatch.use_cookies_with_metadata,
      "action_dispatch.cookies_rotations"         => Rails.application.config.action_dispatch.cookies_rotations,
      "HTTP_HOST"  => "localhost",
      "rack.input" => StringIO.new("")
    }
    fake_request = ActionDispatch::Request.new(env)
    fake_request.cookie_jar.signed[:session_id] = { value: session_record.id, httponly: true, path: "/" }
    cookie_value = fake_request.cookie_jar[:session_id]
    visit root_url
    page.driver.browser.manage.add_cookie(name: "session_id", value: cookie_value, path: "/")
    visit root_url
  end
end
