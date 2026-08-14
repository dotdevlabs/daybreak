class EmailVerificationsMailer < ApplicationMailer
  def verify(user)
    @user             = user
    @verification_url = email_verification_url(user.generate_token_for(:email_verification))
    mail(
      to:      @user.email_address,
      subject: t("auth.email_verification.subject")
    )
  end
end
