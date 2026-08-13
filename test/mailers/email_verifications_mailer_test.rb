require "test_helper"

class EmailVerificationsMailerTest < ActionMailer::TestCase
  setup do
    @user = users(:alice)
    @user.update!(verified_at: nil)
  end

  test "verify email is sent to user's email address" do
    mail = EmailVerificationsMailer.verify(@user)
    assert_equal [ @user.email_address ], mail.to
  end

  test "verify email has correct subject" do
    mail = EmailVerificationsMailer.verify(@user)
    assert_equal I18n.t("auth.email_verification.subject"), mail.subject
  end

  test "verify email body contains verification URL" do
    mail = EmailVerificationsMailer.verify(@user)
    assert_match %r{/email_verifications/}, mail.body.encoded
  end
end
