class SubscriptionMailer < ApplicationMailer
  def confirmed(user, subscription)
    @user         = user
    @subscription = subscription

    mail(
      to:      "#{user.full_name} <#{user.email}>",
      subject: "You're subscribed to Train Like Dubi"
    )
  end

  def cancelled(user, subscription)
    @user         = user
    @subscription = subscription

    mail(
      to:      "#{user.full_name} <#{user.email}>",
      subject: "Your Train Like Dubi subscription has been cancelled"
    )
  end

  def payment_failed(user, subscription)
    @user         = user
    @subscription = subscription

    mail(
      to:      "#{user.full_name} <#{user.email}>",
      subject: "Action required: payment failed for Train Like Dubi"
    )
  end
end
