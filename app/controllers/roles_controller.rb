class RolesController < ApplicationController

  before_filter :require_administrative_privileges
  before_filter :find_role, :except => [ :index ]

  def index
    @roles = Role.all
  end

  def new
    render :layout => false
  end

  def create
    @role = Role.create(params[:role])
    flash[:noticed] = "Role successfully created."
    redirect_to roles_path
  end

  def edit
  end

  def update
    @role.update(params[:role])
  end

  def destroy
    @role.destroy!
    redirect_to roles_path
  end

  private

    def find_role
      params[:id].nil? ? @role = Role.new : @role = Role.get(params[:id])
    end

end