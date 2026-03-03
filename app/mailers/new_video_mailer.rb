class NewVideoMailer < ApplicationMailer
  # Notify a single subscriber about a newly published video.
  # Call via: NewVideoMailer.notify(subscriber, video).deliver_later
  def notify(user, video)
    @user  = user
    @video = video

    mail(
      to:      "#{user.full_name} <#{user.email}>",
      subject: "New video: #{video.title}"
    )
  end
end
