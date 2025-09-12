class UsersController < ApplicationController
  before_action :load_user, only: :show
  def show; end

  def edit; end
  private
  def load_user
    @user = User.find(params[:id])
    return if @user

    # return if @user == current_user

    flash[:danger] = "User not found"
    redirect_to root_path
  end
end
