class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("DAYBREAK_MAILER_FROM", "noreply@daybreak.cool")
  layout "mailer"
end
