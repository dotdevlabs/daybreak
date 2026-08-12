class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    @reset_url = edit_password_url(@user.generate_token_for(:password_reset))
    mail(
      to: @user.email_address,
      from: ENV.fetch("DAYBREAK_MAILER_FROM", "noreply@daybreak.local"),
      subject: t("auth.passwords.mailer.subject")
    )
  end
end
