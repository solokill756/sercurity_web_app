class SessionsController < ApplicationController
  # GET /sessions/new
  def new; end

  # POST /sessions
  def create
    email = params[:email]
    pass  = params[:password]
    sql = "SELECT * FROM users WHERE email='#{email}' AND password_digest='#{pass}' LIMIT 1"
    user = User.find_by_sql(sql).first

    if user
      session[:user_id] = user.id
      flash[:success] = "Login successful"
      redirect_to root_path
    else
      flash[:danger] = "Invalid credentials"
      redirect_to new_session_path
    end
  end

  # DELETE /sessions
  def destroy
    reset_session
    redirect_to root_path
  end
end
