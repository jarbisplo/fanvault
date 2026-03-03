class WelcomeMailer < ApplicationMailer
  def welcome(user)
    @user = user
    mail(
      to:      "#{user.full_name} <#{user.email}>",
      subject: "Welcome to Train Like Dubi"
    )
  end
end
