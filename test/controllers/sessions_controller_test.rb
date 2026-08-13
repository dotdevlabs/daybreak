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
end
