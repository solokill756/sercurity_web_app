class CommentsController < ApplicationController
  before_action :require_login

  # before_action :check_XSS, only: %i(create)

  # POST /events/:event_id/comments
  def create
    load_event
    @comment = @event.comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      flash[:success] = "Comment added successfully!"
    else
      flash[:danger] = "Failed to add comment."
    end
    redirect_to @event
  end

  # DELETE /events/:event_id/comments/:id
  def destroy
    load_comment
    if @comment.user == current_user
      @comment.destroy
      flash[:success] = "Comment deleted."
    else
      flash[:danger] = "Not authorized."
    end
    redirect_to @comment.event
  end

  private

  def comment_params
    params.require(:comment).permit(:content)
  end

  def require_login
    return if current_user

    flash[:danger] = "Please log in to comment."
    redirect_to new_session_path
  end

  def load_event
    @event = Event.find(params[:event_id])
  rescue ActiveRecord::RecordNotFound
    flash[:danger] = "Event not found."
    redirect_to events_path
  end

  def load_comment
    @comment = Comment.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:danger] = "Comment not found."
    redirect_to events_path
  end

  # def check_xss
  #   # Sanitize input to prevent XSS
  #   return unless params[:comment] && params[:comment][:content]

  #   params[:comment][:content] =
  #     Sanitize.fragment(params[:comment][:content],
  #                       Sanitize::Config::RESTRICTED)
  # end
end
