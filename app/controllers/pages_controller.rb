class PagesController < ApplicationController
  def home
    return redirect_to admin_root_path if user_signed_in? && current_user.admin?
    return redirect_to videos_path if user_signed_in? && current_user.can_watch?
  end

  def preview
    # Public — no auth required. Shows locked content teaser.
  end

  def pricing
    @plan = Plan.active.first
  end
end
