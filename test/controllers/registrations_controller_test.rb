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

  # Bug 1 regression: HTML (no-JS) POST path — email in body, never in URL
  test "HTML POST registration with valid email redirects and email not in redirect URL" do
    post registration_path, params: { email_address: "htmluser@example.com" }
    assert_response :redirect
    assert_not_includes response.location, "email_address", "Email param must not appear in redirect URL"
    assert_not_includes response.location, "htmluser", "Email address must not appear in redirect URL"
  end

  test "HTML POST registration with valid email stores pending_user_id in session" do
    post registration_path, params: { email_address: "htmluser@example.com" }
    user = User.find_by!(email_address: "htmluser@example.com")
    assert_equal user.id, session[:pending_user_id]
  end

  test "HTML POST registration with already-verified email redirects (no email in URL)" do
    post registration_path, params: { email_address: users(:alice).email_address }
    assert_response :redirect
    assert_not_includes response.location, users(:alice).email_address
  end

  test "HTML POST registration with invalid email redirects (no email in URL)" do
    post registration_path, params: { email_address: "not-an-email" }
    assert_response :redirect
    assert_not_includes response.location, "not-an-email"
  end
end
