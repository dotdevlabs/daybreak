require "test_helper"

class EmailVerification::ResendsControllerTest < ActionDispatch::IntegrationTest
  test "POST resend enqueues one verification email for unverified pending user" do
    post registration_path, params: { email_address: "resend_test@example.com" }, as: :json
    user = User.find_by!(email_address: "resend_test@example.com")
    user.update!(verified_at: nil)

    assert_emails 1 do
      post email_verification_resend_path, as: :json
    end

    assert_response :success
    data = JSON.parse(response.body)
    assert_equal true, data["sent"]
  end

  test "POST resend does not send email for already-verified user" do
    post registration_path, params: { email_address: "verified_resend@example.com" }, as: :json
    user = User.find_by!(email_address: "verified_resend@example.com")
    user.update!(verified_at: Time.current)

    assert_emails 0 do
      post email_verification_resend_path, as: :json
    end

    assert_response :success
  end

  test "POST resend returns sent true even when no pending user in session" do
    assert_emails 0 do
      post email_verification_resend_path, as: :json
    end

    assert_response :success
    data = JSON.parse(response.body)
    assert_equal true, data["sent"]
  end
end
