class XssDemoController < ApplicationController
  # Skip CSRF protection for demo purposes (DANGEROUS - only for demo)
  skip_before_action :verify_authenticity_token

  def index
    # Main demo page with links to all XSS types
  end

  # ===== STORED XSS DEMO =====
  def stored_xss
    @comments = Comment.all.order(created_at: :desc)
  end

  def create_stored_xss
    # Vulnerable: No input sanitization
    comment = Comment.new(
      content: params[:content],
      user_id: current_user&.id || 1, # Default user for demo
      event_id: 1 # Default event for demo
    )

    if comment.save
      redirect_to stored_xss_path, notice: "Comment added successfully!"
    else
      redirect_to stored_xss_path, alert: "Failed to add comment"
    end
  end

  # ===== REFLECTED XSS DEMO =====
  def reflected_xss
    # Vulnerable: Direct output of user input without sanitization
    @search_term = params[:q]
    @message = params[:message]
  end

  # ===== DOM-BASED XSS DEMO =====
  def dom_based_xss
    # The vulnerability will be in JavaScript on the client side
  end

  # ===== SAFE VERSIONS =====
  def safe_stored_xss
    @comments = Comment.all.order(created_at: :desc)
  end

  def create_safe_stored_xss
    # Safe: Input sanitization
    require "cgi"
    safe_content = CGI.escapeHTML(params[:content])

    comment = Comment.new(
      content: safe_content,
      user_id: current_user&.id || 1,
      event_id: 1
    )

    if comment.save
      redirect_to safe_stored_xss_path, notice: "Safe comment added!"
    else
      redirect_to safe_stored_xss_path, alert: "Failed to add comment"
    end
  end

  def safe_reflected_xss
    # Safe: Input sanitization
    require "cgi"
    @search_term = CGI.escapeHTML(params[:q]) if params[:q]
    @message = CGI.escapeHTML(params[:message]) if params[:message]
  end

  def clear_comments
    Comment.delete_all
    redirect_to stored_xss_path, notice: "All comments cleared!"
  end
end
