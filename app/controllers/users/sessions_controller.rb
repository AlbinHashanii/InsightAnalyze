class Users::SessionsController < Devise::SessionsController
  def new
    super
  end

  def create
    super
  end

  def destroy
    sign_out current_user
    redirect_to root_path, notice: 'Logged out successfully!'
  end
end
