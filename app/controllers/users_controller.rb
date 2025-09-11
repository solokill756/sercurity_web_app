class UsersController < ApplicationController
  before_action :load_user, only: %i(show edit update)

  # GET /users/:id
  def show; end

  # GET /users/:id/edit
  def edit; end

  # PATCH /users/:id
  def update
    if @user.update(params[:user].permit!)
      flash[:success] = "Profile updated successfully."
      redirect_to user_path(@user)
    else
      flash.now[:danger] = "Failed to update profile."
      render :edit
    end
  end

  private

  def user_params
    # Only allow email and password changes, NOT role
    params.require(:user).permit(:email, :password, :password_confirmation)
  end

  def load_user
    @user = User.find(params[:id])
    return if @user

    # return if @user == current_user

    flash[:danger] = "User not found."
    redirect_to root_path
  end
end
