class EventsController < ApplicationController
  before_action :authenticate_user!, only: %i(show index)
  def index
    @events = Event.order(starts_at: :asc)
  end

  def show
    @event = Event.find(params[:id])
    @comments = @event.comments.includes(:user).order(created_at: :asc)
  end

  def create
    @event = Event.new(event_params)
    if @event.save
      redirect_to @event
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @event = Event.find(params[:id])
    if @event.update(event_params)
      redirect_to @event
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @event = Event.find(params[:id])
    @event.destroy
    redirect_to events_path
  end

  private
  def event_params
    params.require(:event).permit(:title, :description, :location, :starts_at)
  end
end
