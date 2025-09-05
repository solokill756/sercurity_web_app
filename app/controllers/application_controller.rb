class ApplicationController < ActionController::Base
  helper_method :current_user
  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end
  private
  def authenticate_user!
    redirect_to new_session_path unless current_user
  end
end
