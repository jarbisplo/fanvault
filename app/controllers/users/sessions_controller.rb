class Users::SessionsController < Devise::SessionsController
  protected

  def after_sign_in_path_for(resource)
    resource.admin? ? admin_root_path : videos_path
  end
end
