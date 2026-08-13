require "test_helper"

class EmailVerificationsControllerTest < ActionDispatch::IntegrationTest
  test "clicking valid verification link verifies user and starts session" do
    user = users(:alice)
    user.update!(verified_at: nil)
    token = user.generate_token_for(:email_verification)

    get email_verification_path(token)

    assert_redirected_to root_path
    assert user.reload.verified?
    assert cookies[:session_id].present?
    assert_not_nil flash[:notice]
  end

  test "already verified user clicking link still redirects to root" do
    user = users(:alice)
    assert user.verified?
    token = user.generate_token_for(:email_verification)

    get email_verification_path(token)

    assert_redirected_to root_path
  end

  test "invalid token redirects to root with alert" do
    get email_verification_path("invalid-token-xyz")
    assert_redirected_to root_path
    assert_not_nil flash[:alert]
  end

  test "used token (second click) is rejected because verified_at changed" do
    user = users(:alice)
    user.update!(verified_at: nil)
    token = user.generate_token_for(:email_verification)

    get email_verification_path(token)
    assert user.reload.verified?

    delete session_path
    get email_verification_path(token)
    assert_redirected_to root_path
    assert_not_nil flash[:alert]
  end
end
