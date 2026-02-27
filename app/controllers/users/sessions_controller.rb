class Users::SessionsController < Devise::SessionsController
  protected

  def after_sign_in_path_for(resource)
    if resource.admin?
      admin_root_path
    elsif resource.can_watch?
      videos_path
    else
      pricing_path
    end
  end
end
