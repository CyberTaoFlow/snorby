class SensorsController < ApplicationController

  before_filter :require_administrative_privileges, :except => [:index, :update_name]
  
  # It returns a sensor's hierarchy tree
  def index
    hierarchy = Sensor.root.hierarchy(10)
    if hierarchy.nil?
      @sensors = []
    else
      @sensors ||= hierarchy.flatten.compact unless hierarchy.nil?
    end
  end
  
  def update_name
    @sensor = Sensor.get(params[:id])
    @sensor.update!(:name => params[:name]) if @sensor
    render :text => @sensor.name
  end
  
  # It destroys a sensor and its childs.
  def destroy
    @sensor = Sensor.get(params[:id])
    
    @sensor.destroy
    respond_to do |format|
      format.html { redirect_to(sensors_path) }
      format.xml  { head :ok }
    end
  end

  # For create a new "Domain Sensor". It will hang the "Root Sensor". 
	def new
		Sensor.create(:parent => Sensor.root, :domain => true)
		redirect_to sensors_path
	end

  # Method used when a sensor is has been dragged and dropped to another sensor.
	def update_parent
		sensor = Sensor.get(params[:sid])
		sensor.update!(:parent_sid => params[:p_sid]) if sensor
		respond_to do |format|
      format.html
      format.js
    end
	end

end
