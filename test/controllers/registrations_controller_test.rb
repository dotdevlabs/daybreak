require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "POST registration with valid email creates pending user" do
    assert_difference "User.count", 1 do
      post registration_path, params: { email_address: "new@example.com" }, as: :json
    end
    assert_response :success
    user = User.find_by!(email_address: "new@example.com")
    assert_nil user.verified_at
  end

  test "POST registration does not create a session cookie" do
    post registration_path, params: { email_address: "new@example.com" }, as: :json
    assert_nil cookies[:session_id]
  end

  test "POST registration stores pending_user_id in session for next step" do
    post registration_path, params: { email_address: "new@example.com" }, as: :json
    post webauthn_registration_challenge_path, as: :json
    assert_response :success
  end

  test "POST registration with already-verified email returns conflict" do
    post registration_path,
      params: { email_address: users(:alice).email_address },
      as: :json
    assert_response :conflict
  end

  test "POST registration with invalid email returns 422" do
    post registration_path, params: { email_address: "not-an-email" }, as: :json
    assert_response :unprocessable_entity
  end

  test "POST registration re-uses existing pending user" do
    post registration_path, params: { email_address: "pending@example.com" }, as: :json
    assert_difference "User.count", 0 do
      post registration_path, params: { email_address: "pending@example.com" }, as: :json
    end
    assert_response :success
  end
end
