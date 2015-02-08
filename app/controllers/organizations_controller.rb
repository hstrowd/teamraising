class OrganizationsController < ApplicationController
  before_action :authenticate_user!, except: [:show, :new]
  before_action :lookup_org, only: [:show, :edit, :update]

  def index
    @orgs = Organization.all
  end

  def new
    if !current_user
      # TODO: Mark this session as wanting to create an organization
      redirect_to new_registration_path(:user)
      return
    end

    @org = Organization.new
  end

  def create
    @org = Organization.new(organization_params)
    @org.creator = current_user
    @org.is_verified = false

    if !@org.save
      render :new
      return
    end

    # Make the current user a member.
    @org.members << current_user

    redirect_to new_organization_fundraiser_path(@org)
    return
  end

  def update
    if !@org.update_attributes(organization_params)
      render :edit
      return
    end

    redirect_to @org
    return
  end


private

  def lookup_org
    @org = Organization.find_by_id(params[:id]) if params[:id]
    @org = Organization.find_by_url_key(params[:url_key]) if !@org && params[:url_key]

    if !@org
      flash[:alert] = 'Unable to find requested organization.'
      if current_user
        redirect_to action: :index
      else
        redirect_to root_url
      end
      return
    end
  end

  def organization_params
    begin
      params.require(:organization)
        .permit(:name,
                :description,
                :url_key,
                :homepage_url,
                :donation_url)
    rescue ActionController::ParameterMissing => e
      logger.info "Failed to parse organization params from #{params.inspect}"
      {}
    end
  end

end
