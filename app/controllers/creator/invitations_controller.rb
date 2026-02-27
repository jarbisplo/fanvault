module Creator
  class InvitationsController < Creator::BaseController
    def index
      @invitations = current_user.sent_invitations.order(created_at: :desc).page(params[:page])
    end

    def new
      @invitation = current_user.sent_invitations.build
    end

    def create
      @invitation = current_user.sent_invitations.build(invitation_params)

      if @invitation.save
        InvitationMailer.invite(@invitation).deliver_later
        redirect_to creator_invitations_path, notice: "Invitation sent to #{@invitation.email}!"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      @invitation = current_user.sent_invitations.find(params[:id])
      @invitation.revoke!
      redirect_to creator_invitations_path, notice: 'Invitation revoked.'
    end

    def revoke
      @invitation = current_user.sent_invitations.find(params[:id])
      @invitation.revoke!
      redirect_back fallback_location: creator_invitations_path, notice: 'Invitation revoked.'
    end

    private

    def invitation_params
      params.require(:invitation).permit(:email, :note)
    end
  end
end
