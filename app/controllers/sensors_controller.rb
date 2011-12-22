class SensorsController < ApplicationController

  respond_to :html, :xml, :json, :js, :csv

  before_filter :require_administrative_privileges, :except => [:index, :update_name]
  before_filter :create_virtual_sensors, :only => [:index]

  before_filter :default_values, :except => [:index, :update_name, :update_ip, :new, :create]
  
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
    @range  = 'last_24'

    cache = Cache.last_24(Time.now.yesterday, Time.now).all(:sensor => @sensor.real_sensors)

    event_values(cache)
    snmp_values
    traps_values

    if @sensor_metrics.last
      @axis = @sensor_metrics.last[:range].join(',')
    elsif @metrics.first.last
      @axis = @metrics.first.last[:range].join(',')
    end

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

  def update_dashboard_rules
    @events = @sensor.events(:order => [:timestamp.desc], :limit => 10)
    @traps  = @sensor.traps(:order => [:timestamp.desc], :limit => 5)
  end

  def update_dashboard_load
  end
  
  def update_dashboard_hardware
  end

  # It destroys a sensor and its childs.
  def destroy
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
    @sensor.update(:parent_sid => params[:p_sid]) if @sensor
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

    def default_values
      @sensor = (Sensor.get(params[:sensor_id]) or Sensor.get(params[:id]))
      @role   = @sensor.chef_role unless @sensor.nil?
      @node   = @sensor.chef_node unless @sensor.nil?
    end

    def event_values (cache)
      @src_metrics = cache.src_metrics
      @dst_metrics = cache.dst_metrics

      @tcp  = cache.protocol_count(:tcp, @range.to_sym)
      @udp  = cache.protocol_count(:udp, @range.to_sym)
      @icmp = cache.protocol_count(:icmp, @range.to_sym)

      @signature_metrics = cache.signature_metrics

      @high   = cache.severity_count(:high, @range.to_sym)
      @medium = cache.severity_count(:medium, @range.to_sym)
      @low    = cache.severity_count(:low, @range.to_sym)

      @event_count = @high.sum + @medium.sum + @low.sum

      @sensor_metrics = cache.sensor_metrics(@range.to_sym)
    end

    def traps_values
      @trap_count = @sensor.traps(:timestamp.gte => Time.now.yesterday).size
    end

    def snmp_values
      @snmp = Snmp.last_24(Time.now.yesterday, Time.now).all(:sensor => @sensor.virtual_sensors)
      @metrics = @snmp.metrics(@range.to_sym)

      @high_snmp    = @snmp.severity_count(:high, @range.to_sym)
      @medium_snmp  = @snmp.severity_count(:medium, @range.to_sym)
      @low_snmp     = @snmp.severity_count(:low, @range.to_sym)
      
      @snmp_count = @high_snmp.sum + @medium_snmp.sum + @low_snmp.sum
    end

end
