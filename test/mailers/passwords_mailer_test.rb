require "test_helper"

class PasswordsMailerTest < ActionMailer::TestCase
  test "reset email is sent to user's email address" do
    user = users(:alice)
    mail = PasswordsMailer.reset(user)
    assert_equal [ user.email_address ], mail.to
  end

  test "reset email has correct subject" do
    user = users(:alice)
    mail = PasswordsMailer.reset(user)
    assert_equal I18n.t("auth.passwords.mailer.subject"), mail.subject
  end

  test "reset email body contains password reset URL" do
    user = users(:alice)
    mail = PasswordsMailer.reset(user)
    assert_match %r{/passwords/.+/edit}, mail.body.encoded
  end

  test "reset email body contains greeting" do
    user = users(:alice)
    mail = PasswordsMailer.reset(user)
    assert_match I18n.t("auth.passwords.mailer.greeting"), mail.body.encoded
  end
end
