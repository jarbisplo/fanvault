class InvitationMailer < ApplicationMailer
  def invite(invitation)
    @invitation = invitation
    @creator    = invitation.creator
    @accept_url = invitation_url(invitation.token)

    mail(
      to:      invitation.email,
      subject: "#{@creator.full_name} invited you to FanVault"
    )
  end
end
