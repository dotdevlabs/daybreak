require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "DELETE session destroys session record and redirects to root" do
    sign_in_as(users(:alice))
    assert_difference "Session.count", -1 do
      delete session_path
    end
    assert_redirected_to root_path
  end

  test "DELETE session when unauthenticated redirects to root" do
    delete session_path
    assert_redirected_to root_path
  end

  test "after DELETE session the auth overlay is shown again" do
    sign_in_as(users(:alice))
    delete session_path
    follow_redirect!
    assert_select ".auth-overlay"
  end

  # Bug 1 regression: no-JS sign-in degraded path — email in body, never in URL
  test "POST session (no-JS sign-in fallback) redirects to root" do
    post session_path, params: { email_address: users(:alice).email_address }
    assert_redirected_to root_path
  end

  test "POST session does not place email in the redirect URL" do
    post session_path, params: { email_address: users(:alice).email_address }
    assert_response :redirect
    refute_includes response.location, "email_address"
    refute_includes response.location, users(:alice).email_address
  end

  test "POST session is accessible when unauthenticated (no require_authentication redirect)" do
    post session_path, params: { email_address: "anyone@example.com" }
    assert_redirected_to root_path
  end
end
