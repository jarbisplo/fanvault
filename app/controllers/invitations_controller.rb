class InvitationsController < ApplicationController
  before_action :set_invitation, only: [:show, :accept]

  def show
    if @invitation.expired?
      redirect_to root_path, alert: 'This invitation has expired.'
    elsif @invitation.accepted?
      redirect_to root_path, notice: 'This invitation has already been used.'
    end
  end

  def accept
    return redirect_to new_user_session_path, alert: 'Sign in to accept.' unless user_signed_in?

    if @invitation.accept!(current_user)
      redirect_to subscriber_root_path,
                  notice: "You're now subscribed to #{@invitation.creator.full_name}!"
    else
      redirect_to invitation_path(@invitation.token), alert: 'Could not accept invitation.'
    end
  end

  private

  def set_invitation
    @invitation = Invitation.pending_valid.find_by!(token: params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: 'Invitation not found or expired.'
  end
end
