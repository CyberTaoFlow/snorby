class SensorsController < ApplicationController

  before_filter :require_administrative_privileges, :except => [:index, :update_name]
  before_filter :create_virtual_sensors, :only => [:index]
  
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

  def update_ip
    @sensor = Sensor.get(params[:id])
    @sensor.update!(:ipdir => params[:ip]) if @sensor
    render :text => @sensor.ipdir
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

  private

    def create_virtual_sensors
      sensors = Sensor.all(:domain => false, :parent_sid => nil)

      sensors.each do |sensor|
        if sensor.hostname.include? ':'
          pname = /(.+):/.match(sensor.hostname)[1]
        else
          pname = sensor.hostname
        end
        p_sensor = Sensor.first(:name => pname.capitalize, :hostname => pname, :domain => true)
        p_sensor = Sensor.create(:name => pname.capitalize, :hostname => pname, :domain => true, :parent => Sensor.root) if p_sensor.nil?
        sensor.update(:parent => p_sensor)
      end

      # Needed to reload the object. Without that, index need to be reload twice to view the sensors created.
      redirect_to sensors_path if sensors.present?
    end

end
