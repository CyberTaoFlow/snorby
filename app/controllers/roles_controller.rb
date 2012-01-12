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
    if params[:sensor_sid].present?
      @role.roleSensors.all(:sensor_sid => params[:sensor_sid]).destroy
      redirect_to roles_path(@role)
    elsif params[:user_id].present?
      @role.roleUsers.all(:user_id => params[:user_id]).destroy
      redirect_to roles_path(@role)
    else
      @role.destroy!
      redirect_to roles_path
    end
  end

  def add_users
    @role = Role.get(params[:role_id])
    @users = User.all - @role.users
    render :layout => false
  end

  def add_sensors
    @role = Role.get(params[:role_id])
    @sensors = Sensor.all(:domain => true) - @role.sensors
    render :layout => false
  end

  private

    def find_role
      params[:id].nil? ? @role = Role.new : @role = Role.get(params[:id])
    end

end