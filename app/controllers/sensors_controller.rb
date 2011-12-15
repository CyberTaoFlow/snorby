class SensorsController < ApplicationController

  respond_to :html, :xml, :json, :js, :csv

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

  def show
    @sensor = Sensor.get(params[:id])
    @role   = @sensor.chef_role
    @node   = @sensor.chef_node

    @range  = params[:range].blank? ? 'last_24' : params[:range]

    cache           = Cache.last_24(Time.now.yesterday, Time.now).all(:sensor => @sensor.real_sensors)
    sensor_metrics  = cache.sensor_metrics(@range.to_sym)

    @axis   = sensor_metrics.last[:range].join(',')
    @high   = cache.severity_count(:high, @range.to_sym)
    @medium = cache.severity_count(:medium, @range.to_sym)
    @low    = cache.severity_count(:low, @range.to_sym)

  end

  def update_name
    @sensor = Sensor.get(params[:id])
    @sensor.update(:name => params[:name]) if @sensor
    render :text => @sensor.name
  end

  def update_ip
    @sensor = Sensor.get(params[:id])
    @sensor.update(:ipdir => params[:ip]) if @sensor
    render :text => @sensor.ipdir
  end

  def update_dashboard_info
    update_dashboard_type "info"
    
    @range  = params[:range].blank? ? 'last_24' : params[:range]

    cache           = Cache.last_24(Time.now.yesterday, Time.now).all(:sensor => @sensor.real_sensors)
    sensor_metrics  = cache.sensor_metrics(@range.to_sym)

    @axis   = sensor_metrics.last[:range].join(',')
    @high   = cache.severity_count(:high, @range.to_sym)
    @medium = cache.severity_count(:medium, @range.to_sym)
    @low    = cache.severity_count(:low, @range.to_sym)
    
    respond_to do |format|
        format.js
    end

  end

  def update_dashboard_rules
    update_dashboard_type "rules"
  end

  def update_dashboard_load
    update_dashboard_type "load"
  end
  
  def update_dashboard_hardware
    update_dashboard_type "hardware"
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

  def new
    @sensor = Sensor.new
    render :layout => false
	end

  def create
    params[:sensor][:domain]=true if params[:sensor][:domain].nil?
    @sensor = Sensor.create(params[:sensor])
    @sensor.update(:parent => Sensor.root, :domain => true)

    redirect_to sensors_path
  end

  def edit
    @sensor = Sensor.get(params[:id])
    render :layout => false
  end

  def update
    @sensor = Sensor.get(params[:id])
    if @sensor.update(params[:sensor])
      redirect_to(sensors_path, :notice => 'Sensor was successfully updated.')
    else
      redirect_to(sensors_path, :notice => 'Was an error updating the sensor.')
    end
  end

  # Method used when a sensor is has been dragged and dropped to another sensor.
  def update_parent
    sensor = Sensor.get(params[:sid])
    sensor.update(:parent_sid => params[:p_sid]) if sensor
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
          pname = /([^:]+):/.match(sensor.hostname)[1]
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

    def update_dashboard_type(type=nil)
      @sensor = Sensor.get(params[:sensor_id])
      @role   = @sensor.chef_role unless @sensor.nil?
      @node   = @sensor.chef_node unless @sensor.nil?
    end


end
