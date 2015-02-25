class EventsController < ApplicationController
  include DateHelper

  respond_to :html, :json
  layout "raw", only: [:dashboard]

  before_action :authenticate_user!, except: [:show]
  before_action :lookup_event, except: [:new, :create]

  def new
    fundraiser_id = params[:fundraiser_id]
    return if !is_valid_fundraiser?(fundraiser_id)
    fundraiser = Fundraiser.find(fundraiser_id)

    @event = Event.new(fundraiser: fundraiser)
    if (!fundraiser.has_started?)
      @event.start_time = fundraiser.pledge_start_time
      @event.end_time = fundraiser.pledge_start_time
    end
  end

  def create
    return if !is_valid_fundraiser?(event_params[:fundraiser_id])

    @event = Event.new(event_params)
    @event.creator = current_user

    if !@event.save
      render :new
      return
    end

    redirect_to @event
    return
  end

  def update
    if !@event.update_attributes(event_params)
      render :edit
      return
    end

    redirect_to @event
    return
  end

  def dashboard
  end

  def pledge_breakdown
    pledge_breakdown = @event.teams.order(:name).inject([]) do |donations, team|
      data_label = "#{team.name} (#{team.pledges.count})"
      donations << [data_label, team.pledge_total]
      donations
    end

    respond_with(pledge_breakdown)
  end

private

  def lookup_event
    @event = Event.find_by_id(params[:id]) if params[:id]

    if !@event
      respond_to do |format|
        format.html {
          flash[:alert] = 'Unable to find requested event.'
          if current_user
            redirect_to organizations_path
          else
            redirect_to root_path
          end
        }
        format.json { render :json => {:error => 'Event not found.'}.to_json, :status => 404 }
      end
    end
  end

  def is_valid_fundraiser?(fundraiser_id)
    if fundraiser_id && (fundraiser = Fundraiser.find_by_id(fundraiser_id))
      members = fundraiser.organization.members
      return true if members.to_a.index { |user| user.id == current_user.id }
    end

    flash[:alert] = 'Please select the organization for which you\'d like to create a new event.'
    redirect_to organizations_path
    return false
  end

  def event_params
    input_params = {}
    begin
      input_params = params.require(:event)
        .permit(:title,
                :description,
                :fundraiser_id,
                :start_time,
                :end_time,
                :team_descriptor_id)
    rescue ActionController::ParameterMissing => e
      logger.info "Failed to parse event params from #{params.inspect}"
    end

    # Parse date values.
    if input_params.has_key?(:start_time)
      input_params[:start_time] = parseIso8601Date(input_params[:start_time])
    end
    if input_params.has_key?(:end_time)
      input_params[:end_time] = parseIso8601Date(input_params[:end_time])
    end

    input_params
  end
end
