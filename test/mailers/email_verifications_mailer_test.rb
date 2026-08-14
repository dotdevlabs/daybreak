require "test_helper"

class EmailVerificationsMailerTest < ActionMailer::TestCase
  setup do
    @user = users(:alice)
    @user.update!(verified_at: nil)
    @mail = EmailVerificationsMailer.verify(@user)
  end

  test "renders both html and text parts" do
    assert_equal %w[text/plain text/html], @mail.parts.map { |p| p.mime_type }
  end

  test "sends to the user email address" do
    assert_equal [ @user.email_address ], @mail.to
  end

  test "from address is a daybreak.cool address" do
    assert_match /@daybreak\.cool\z/, Array(@mail.from).first
  end

  test "subject is the localized verification subject" do
    assert_equal I18n.t("auth.email_verification.subject"), @mail.subject
  end

  test "body contains the email verification URL" do
    assert_match %r{https?://[^/]+/email_verifications/}, @mail.body.encoded
  end
end
