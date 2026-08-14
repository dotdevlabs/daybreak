require "test_helper"

# Use localhost so WebAuthn's rpId ("localhost") matches the browser's origin.
# 127.0.0.1 and localhost are different effective domains for WebAuthn validation.
Capybara.server_host = "localhost"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]
end
