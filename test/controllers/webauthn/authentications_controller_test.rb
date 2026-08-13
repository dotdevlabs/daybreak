require "test_helper"

class Webauthn::AuthenticationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @fake_client = WebAuthn::FakeClient.new("http://www.example.com")
    @user = users(:alice)
    @user.update!(verified_at: nil)

    post registration_path, params: { email_address: @user.email_address }, as: :json
    post webauthn_registration_challenge_path, as: :json
    options = JSON.parse(response.body)
    credential = @fake_client.create(challenge: options["challenge"])
    post webauthn_registration_path, params: { credential: credential }, as: :json
    @alice_credential = @user.reload.credentials.last
    @user.verify!
  end

  test "POST /webauthn/authentication/challenge returns options for known user" do
    post webauthn_authentication_challenge_path,
      params: { email_address: @user.email_address },
      as: :json
    assert_response :success
    data = JSON.parse(response.body)
    assert data.key?("challenge")
  end

  test "full authentication ceremony signs in a verified user" do
    post webauthn_authentication_challenge_path,
      params: { email_address: @user.email_address },
      as: :json
    options = JSON.parse(response.body)
    assertion = @fake_client.get(challenge: options["challenge"])

    post webauthn_authentication_path,
      params: { credential: assertion, email_address: @user.email_address },
      as: :json

    assert_response :success
    data = JSON.parse(response.body)
    assert_equal root_path, data["redirect_url"]
    assert cookies[:session_id].present?
  end

  test "authentication updates sign_count" do
    initial_count = @alice_credential.sign_count
    post webauthn_authentication_challenge_path,
      params: { email_address: @user.email_address }, as: :json
    options = JSON.parse(response.body)
    assertion = @fake_client.get(challenge: options["challenge"])
    post webauthn_authentication_path,
      params: { credential: assertion, email_address: @user.email_address }, as: :json

    assert @alice_credential.reload.sign_count >= initial_count
  end

  test "authentication refused for unverified user" do
    @user.update!(verified_at: nil)
    post webauthn_authentication_challenge_path,
      params: { email_address: @user.email_address }, as: :json
    options = JSON.parse(response.body)
    assertion = @fake_client.get(challenge: options["challenge"])
    post webauthn_authentication_path,
      params: { credential: assertion, email_address: @user.email_address }, as: :json

    assert_response :forbidden
    data = JSON.parse(response.body)
    assert_equal "not_verified", data["error"]
    assert_nil cookies[:session_id]
  end
end
