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
end
