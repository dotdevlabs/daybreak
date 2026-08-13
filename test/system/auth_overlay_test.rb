require "application_system_test_case"

class AuthOverlayTest < ApplicationSystemTestCase
  fixtures :users

  teardown do
    User.where.not(id: [ users(:alice).id, users(:singleton).id ]).destroy_all
  end

  # Wait for the Stimulus auth-overlay controller to connect before interacting.
  # The controller sets data-connected="" in connect(), so once this selector
  # resolves we know the form's submit handler is registered.
  def wait_for_overlay
    find("[data-controller='auth-overlay'][data-connected]")
  end

  test "submitting valid email advances to passkey registration step" do
    visit root_url
    wait_for_overlay
    find("[data-auth-overlay-target='signupEmailInput']").set("newuser@example.com")
    find("[data-auth-overlay-target='signupEmail'] [type='submit']").click

    assert_selector "[data-auth-overlay-target='signupMethod']"
    assert_no_selector "[data-auth-overlay-target='signupEmail']"
  end

  test "clicking email fallback on passkey step transitions to check-email" do
    visit root_url
    wait_for_overlay
    find("[data-auth-overlay-target='signupEmailInput']").set("newuser@example.com")
    find("[data-auth-overlay-target='signupEmail'] [type='submit']").click
    assert_selector "[data-auth-overlay-target='signupMethod']"

    find("[data-action='auth-overlay#sendEmailFallback']").click

    assert_selector "[data-auth-overlay-target='checkEmail']"
    assert_no_selector "[data-auth-overlay-target='signupMethod']"
  end

  test "already-registered email shows conflict error and stays on email step" do
    visit root_url
    wait_for_overlay
    find("[data-auth-overlay-target='signupEmailInput']").set(users(:alice).email_address)
    find("[data-auth-overlay-target='signupEmail'] [type='submit']").click

    assert_selector "[data-auth-overlay-target='errorMessage']"
    assert_selector "[data-auth-overlay-target='signupEmail']"
    assert_no_selector "[data-auth-overlay-target='signupMethod']"
  end

  # Bug 2: Passkey feature detection uses window.PublicKeyCredential, not helper load state.
  test "passkey detection: Chrome headless exposes PublicKeyCredential (positive capability)" do
    visit root_url
    wait_for_overlay

    pk_available = page.evaluate_script("typeof window.PublicKeyCredential !== 'undefined'")
    assert pk_available, "Headless Chrome must expose window.PublicKeyCredential for passkey detection tests to be meaningful"
  end

  test "passkey detection: reports unsupported only when PublicKeyCredential is absent" do
    visit root_url
    wait_for_overlay

    # Advance to signup-method step (drives JS fetch path)
    find("[data-auth-overlay-target='signupEmailInput']").set("detecttest@example.com")
    find("[data-auth-overlay-target='signupEmail'] [type='submit']").click
    assert_selector "[data-auth-overlay-target='signupMethod']:not([hidden])"

    # Now strip PublicKeyCredential to simulate a browser without WebAuthn support
    page.execute_script("window.PublicKeyCredential = undefined")

    # Click passkey button — should show "not supported" because PublicKeyCredential is gone
    find("[data-action='auth-overlay#startPasskeyRegistration']").click
    assert_selector "[data-auth-overlay-target='errorMessage']:not([hidden])",
                    text: /not supported/i
  end

  # Verifies that the vendored @github/webauthn-json module loads successfully in
  # the browser via dynamic import. A broken/nonexistent CDN pin causes the promise
  # to reject with a network or 404 error; a vendored file resolves with the module.
  test "webauthn-json module loads from vendored asset (create and get are functions)" do
    visit root_url
    wait_for_overlay

    result = page.evaluate_async_script(<<~JS)
      var done = arguments[0];
      import('@github/webauthn-json')
        .then(function(m) { done('loaded:' + typeof m.create + ':' + typeof m.get); })
        .catch(function(e) { done('error:' + e.message); });
    JS

    assert_equal "loaded:function:function", result,
      "WebAuthn helper module must load with create and get as functions — got: #{result}"
  end

  # Verifies that clicking "Use a passkey" does NOT show the module-load failure
  # message. With a broken importmap pin, ensureWebAuthnHelper() throws and the
  # controller displays "Passkey helper is unavailable." With the vendored fix the
  # module loads and the code proceeds to the challenge fetch (which we mock out).
  test "clicking Use a passkey does not show Passkey helper is unavailable" do
    visit root_url
    wait_for_overlay

    find("[data-auth-overlay-target='signupEmailInput']").set("passkeyloadtest@example.com")
    find("[data-auth-overlay-target='signupEmail'] [type='submit']").click
    assert_selector "[data-auth-overlay-target='signupMethod']:not([hidden])"

    # Intercept WebAuthn server calls so we can observe the module-load outcome
    # without triggering a real authenticator ceremony in headless Chrome.
    page.execute_script(<<~JS)
      window.__origFetch = window.fetch;
      window.fetch = function(url, opts) {
        if (typeof url === 'string' && url.includes('/webauthn/')) {
          return Promise.reject(new Error('mocked-challenge-for-test'));
        }
        return window.__origFetch(url, opts);
      };
    JS

    find("[data-action='auth-overlay#startPasskeyRegistration']").click

    # An error IS expected (the mocked challenge fetch rejects), but it must NOT
    # be the module-load failure. If the module loaded, the code reaches the
    # challenge fetch, hits the mock, and shows a different error.
    assert_selector "[data-auth-overlay-target='errorMessage']:not([hidden])"
    assert_no_text "Passkey helper is unavailable",
      "The WebAuthn helper module must load successfully; the 'unavailable' branch must not be reached"
  end
end
