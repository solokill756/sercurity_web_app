class SessionsController < ApplicationController
  # GET /sessions/new
  def new; end

  # POST /sessions
  def create
    find_user
    return if performed?

    if @user&.authenticate(params[:password])
      session[:user_id] = @user.id
      flash[:success] = "Login successful"
      redirect_to root_path
    else
      flash[:danger] = "Invalid credentials"
      render :new, status: :unprocessable_entity
    end
  end

  # DELETE /sessions
  def destroy
    reset_session
    redirect_to root_path
  end

  private

  def find_user
    @user ||= User.find_by(email: params[:email])
    return if @user

    flash[:danger] = "Invalid credentials"
    render :new, status: :unprocessable_entity
  end
end
