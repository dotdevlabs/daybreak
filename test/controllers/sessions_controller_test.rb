require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "POST session with valid credentials creates session and redirects to root" do
    user = users(:alice)
    assert_difference "Session.count", 1 do
      post session_path, params: { email_address: user.email_address, password: "password123" }
    end
    assert_redirected_to root_path
    assert cookies[:session_id].present?
  end

  test "POST session with invalid credentials returns 422 and renders overlay in login mode" do
    post session_path, params: { email_address: "alice@example.com", password: "wrongpassword" }
    assert_response :unprocessable_entity
    assert_select ".auth-overlay"
  end

  test "POST session with invalid credentials shows error message" do
    post session_path, params: { email_address: "alice@example.com", password: "wrongpassword" }
    assert_select ".auth-overlay__error"
  end

  test "POST session with unknown email returns 422" do
    post session_path, params: { email_address: "nobody@example.com", password: "password123" }
    assert_response :unprocessable_entity
  end

  test "DELETE session destroys session record and redirects to root" do
    user = users(:alice)
    post session_path, params: { email_address: user.email_address, password: "password123" }
    assert_difference "Session.count", -1 do
      delete session_path
    end
    assert_redirected_to root_path
  end

  test "DELETE session when unauthenticated redirects to root" do
    delete session_path
    assert_redirected_to root_path
  end

  test "after DELETE session the overlay is shown again" do
    user = users(:alice)
    post session_path, params: { email_address: user.email_address, password: "password123" }
    delete session_path
    follow_redirect!
    assert_select ".auth-overlay"
  end
end
