require "application_system_test_case"

class PasskeyE2ETest < ApplicationSystemTestCase
  fixtures :users

  setup do
    @original_webauthn_origins = WebAuthn.configuration.allowed_origins.dup
    @original_webauthn_rp_id = WebAuthn.configuration.rp_id

    # Override WebAuthn config to match the actual browser origin for this test.
    # Capybara.server_host is "localhost" (set in application_system_test_case.rb),
    # so the browser origin is http://localhost:PORT and rpId must be "localhost".
    port = Capybara.server_port
    WebAuthn.configuration.allowed_origins = [ "http://localhost:#{port}" ]
    WebAuthn.configuration.rp_id = "localhost"
  end

  teardown do
    WebAuthn.configuration.allowed_origins = @original_webauthn_origins
    WebAuthn.configuration.rp_id = @original_webauthn_rp_id
    User.where.not(id: [ users(:alice).id, users(:singleton).id ]).destroy_all
  end

  test "register with passkey then sign in with passkey (virtual authenticator, no create/get stubbing)" do
    # Add a Chrome DevTools Protocol virtual authenticator. This runs in-process
    # and satisfies real navigator.credentials calls without any OS dialog.
    authenticator_options = Selenium::WebDriver::VirtualAuthenticatorOptions.new(
      protocol: :ctap2,
      transport: :internal,
      has_resident_key: true,
      has_user_verification: true,
      is_user_verified: true
    )
    page.driver.browser.add_virtual_authenticator(authenticator_options)

    test_email = "passkey-e2e@example.com"

    # ── Registration ──────────────────────────────────────────────────────────
    visit root_url
    find("[data-controller='auth-overlay'][data-connected]")

    find("[data-auth-overlay-target='signupEmailInput']").set(test_email)
    find("[data-auth-overlay-target='signupEmail'] [type='submit']").click
    assert_selector "[data-auth-overlay-target='signupMethod']:not([hidden])"

    find("[data-action='auth-overlay#startPasskeyRegistration']").click

    # The REAL create() call runs against the virtual authenticator here.
    # If the { publicKey: options } wrapper is missing, the library throws
    # "Missing key: publicKey" and errorMessage becomes visible instead.
    assert_selector "[data-auth-overlay-target='checkEmail']:not([hidden])", wait: 15
    assert_no_selector "[data-auth-overlay-target='errorMessage']:not([hidden])"

    # ── Verify the new user in-process (bypass the email link for the test) ──
    User.find_by!(email_address: test_email).verify!

    # ── Sign-in ───────────────────────────────────────────────────────────────
    visit root_url
    find("[data-controller='auth-overlay'][data-connected]")

    find("[data-action='auth-overlay#showSignin']").click
    assert_selector "[data-auth-overlay-target='signinEmail']:not([hidden])"

    find("[data-auth-overlay-target='signinEmailInput']").set(test_email)
    find("[data-auth-overlay-target='signinEmail'] [type='submit']").click

    # The REAL get() call runs against the virtual authenticator. On success the
    # JS does window.location.href = redirect_url. The reloaded page is the
    # authenticated dashboard, which does not render the auth overlay.
    assert_no_selector ".auth-overlay", wait: 15
  end
end
