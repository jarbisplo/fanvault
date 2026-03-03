class DeviseMailer < Devise::Mailer
  helper :application
  default from: "Train Like Dubi <noreply@#{ENV.fetch('MAILGUN_DOMAIN', 'mail.trainlikedubi.com')}>"
  layout 'mailer'
end
