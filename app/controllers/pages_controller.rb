class PagesController < ApplicationController
  def home
    redirect_to videos_path if user_signed_in? && current_user.can_watch?
    redirect_to admin_root_path if user_signed_in? && current_user.admin?
  end

  def pricing
    @plan = Plan.active.first
  end
end
