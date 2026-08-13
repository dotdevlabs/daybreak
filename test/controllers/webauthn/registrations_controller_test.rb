require "test_helper"

class Webauthn::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @fake_client = WebAuthn::FakeClient.new("http://www.example.com")
    post registration_path, params: { email_address: "passkey@example.com" }, as: :json
    @user = User.find_by!(email_address: "passkey@example.com")
  end

  test "POST /webauthn/registration/challenge returns WebAuthn options" do
    post webauthn_registration_challenge_path, as: :json
    assert_response :success
    data = JSON.parse(response.body)
    assert data.key?("challenge")
    assert data.key?("user")
  end

  test "full registration ceremony creates credential and sends verification email" do
    post webauthn_registration_challenge_path, as: :json
    options = JSON.parse(response.body)
    credential = @fake_client.create(challenge: options["challenge"])

    assert_emails 1 do
      post webauthn_registration_path,
        params: { credential: credential },
        as: :json
    end
    assert_response :success
    data = JSON.parse(response.body)
    assert_equal "check_email", data["step"]
    assert_equal 1, @user.reload.credentials.count
  end

  test "registration leaves user unverified and no session cookie" do
    post webauthn_registration_challenge_path, as: :json
    options = JSON.parse(response.body)
    credential = @fake_client.create(challenge: options["challenge"])
    post webauthn_registration_path, params: { credential: credential }, as: :json

    assert_nil @user.reload.verified_at
    assert_nil cookies[:session_id]
  end

  test "invalid credential returns 422" do
    post webauthn_registration_challenge_path, as: :json
    fake_id      = Base64.urlsafe_encode64("fake_credential_id_xx", padding: false)
    fake_chall   = Base64.urlsafe_encode64("wrong_challenge_value", padding: false)
    fake_cdo     = Base64.urlsafe_encode64({ type: "webauthn.create", challenge: fake_chall, origin: "http://www.example.com" }.to_json, padding: false)
    fake_ao      = Base64.urlsafe_encode64("not_valid_cbor_bytes!!", padding: false)
    post webauthn_registration_path,
      params: { credential: { id: fake_id, rawId: fake_id, type: "public-key",
                              response: { attestationObject: fake_ao, clientDataJSON: fake_cdo } } },
      as: :json
    assert_response :unprocessable_entity
  end
end
