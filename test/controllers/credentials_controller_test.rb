require "test_helper"

class CredentialsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
    sign_in_as(@user)
    @fake_client = WebAuthn::FakeClient.new("http://www.example.com")
  end

  def add_credential(nickname: "Test Passkey")
    post credentials_challenge_path, as: :json
    options = JSON.parse(response.body)
    credential = @fake_client.create(challenge: options["challenge"])
    post credentials_path, params: { credential: credential, nickname: nickname }, as: :json
    follow_redirect! if response.redirect?
  end

  test "GET /credentials lists user passkeys" do
    get credentials_path
    assert_response :success
  end

  test "adding a passkey stores a new credential" do
    assert_difference "@user.credentials.count", 1 do
      add_credential
    end
  end

  test "renaming a passkey updates nickname" do
    add_credential(nickname: "Old Name")
    cred = @user.credentials.last
    patch credential_path(cred), params: { nickname: "New Name" }
    assert_equal "New Name", cred.reload.nickname
    assert_redirected_to credentials_path
  end

  test "removing a passkey when multiple exist succeeds" do
    add_credential(nickname: "Passkey 1")
    add_credential(nickname: "Passkey 2")
    first_cred = @user.credentials.reload.first
    assert_difference "@user.credentials.count", -1 do
      delete credential_path(first_cred)
    end
    assert_redirected_to credentials_path
  end

  test "removing the last passkey is refused" do
    add_credential(nickname: "Only Key")
    @user.credentials.where.not(nickname: "Only Key").destroy_all
    cred = @user.credentials.reload.first
    assert_no_difference "@user.credentials.count" do
      delete credential_path(cred)
    end
    assert_redirected_to credentials_path
    assert flash[:alert].present?
  end

  test "credentials require authentication" do
    delete session_path
    get credentials_path
    assert_redirected_to root_path
  end
end
