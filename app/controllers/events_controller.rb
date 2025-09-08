class EventsController < ApplicationController
  before_action :authenticate_user!, only: %i(show index)
  #  GET /events
  def index
    @events = Event.order(starts_at: :asc)
  end

  # GET /events/new
  def show
    get_event
    @comments = @event.comments.includes(:user).order(created_at: :asc)
  end

  # GET /events/new
  def create
    @event = Event.new(event_params)
    if @event.save
      redirect_to @event
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /events/:id/edit
  def update
    get_event
    if @event.update(event_params)
      redirect_to @event
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /events/:id
  def destroy
    get_event
    @event.destroy
    redirect_to events_path
  end

  private
  def event_params
    params.require(:event).permit(:title, :description, :location, :starts_at)
  end

  def get_event
    @event = Event.find(params[:id])

    return if @event

    flash[:danger] = "Event not found."
    redirect_to events_path
  end
end
