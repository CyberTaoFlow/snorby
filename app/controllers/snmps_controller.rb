class SnmpsController < ApplicationController
  respond_to :html, :xml, :json, :js, :csv
  
  helper_method :sort_column, :sort_direction
  
  def index

    raise ActionController::RoutingError.new('Not Found') unless Sensor.get(params[:sensor_id]).domain

    @sensor = Sensor.get(params[:sensor_id])

    @now = Time.now

    @range = params[:range].blank? ? 'last_3_hours' : params[:range]

    set_defaults
    virtual_sensors = @sensor.virtual_sensors

    @snmp = @snmp.all(:sensor => virtual_sensors)

    @last_snmp = @snmp.sort{|a, b| a.timestamp <=> b.timestamp}.last

    @metrics = @snmp.metrics(@range.to_sym)
    
    @high_snmp    = @snmp.severity_count(:high, @range.to_sym)
    @medium_snmp  = @snmp.severity_count(:medium, @range.to_sym)
    @low_snmp     = @snmp.severity_count(:low, @range.to_sym)
    
    @snmp_count = @high_snmp.sum + @medium_snmp.sum + @low_snmp.sum
    
    if @metrics.first.last and @range == 'last_3_hours'
      # take only half of the items for axis
      index = 0
      @axis = @metrics.first.last[:range].map{|x| index += 1; index % 2 == 1 ? x : "' '"}.join(',')
    elsif @metrics.first.last
      @axis = @metrics.first.last[:range].join(',')
    end
    
    @sensors = Sensor.all(:sid => virtual_sensors.map{|x| x.sid}, :limit => 5)
    
    #@traps = Trap.all.sort{|x, y| y.timestamp <=> x.timestamp}.first(5)
    @traps  = Trap.all(:sensor => virtual_sensors, :order => [:timestamp.desc], :limit => 10)
    
    respond_to do |format|
      format.html
      format.js
      format.pdf do
        render :pdf => "Snorby Snmp Report - #{@start_time.strftime('%A-%B-%d-%Y-%I-%M-%p')} - #{@end_time.strftime('%A-%B-%d-%Y-%I-%M-%p')}", :template => "snmps/index.pdf.erb", :layout => 'pdf.html.erb', :stylesheets => ["pdf"]
      end
    end
    
  end
  
  def results    
    params[:sort] = sort_column
    params[:direction] = sort_direction

    @snmps = Snmp.sorty(params)
  end
  
  private
  
  def set_defaults
    case @range.to_sym
    when :last_3_hours
      
      @start_time = @now - 3.hours
      @end_time = @now
      @snmp = Snmp.last_3_hours(@start_time, @end_time)
      
    when :today
      
      @start_time = @now.beginning_of_day
      @end_time = @now.end_of_day
      @snmp = Snmp.today
    
    when :yesterday
      
      @start_time = (@now - 1.day).beginning_of_day
      @end_time = (@now - 1.day).end_of_day
      @snmp = Snmp.yesterday
      
    when :week
      
      @start_time = @now.beginning_of_week
      @end_time = @now.end_of_week
      @snmp = Snmp.this_week
    
    when :last_week
      @snmp = Snmp.last_week
      @start_time = (@now - 1.week).beginning_of_week
      @end_time = (@now - 1.week).end_of_week
  
    when :month
      
      @start_time = @now.beginning_of_month
      @end_time = @now.end_of_month
      @snmp = Snmp.this_month

    when :last_month
      @snmp = Snmp.last_month
      @start_time = (@now - 1.months).beginning_of_month
      @end_time = (@now - 1.months).end_of_month  

    when :quarter

      @start_time = @now.beginning_of_quarter
      @end_time = @now.end_of_quarter
      @snmp = Snmp.this_quarter
            
    when :year
      
      @start_time = @now.beginning_of_year
      @end_time = @now.end_of_year
      @snmp = Snmp.this_year
      
    else
      
      @start_time = @now.beginning_of_day
      @end_time = @now.end_of_day
      @snmp = Snmp.today
      
    end  
  end  
  
  def sort_column
    return :timestamp unless params.has_key?(:sort)
    return params[:sort].to_sym if Snmp::SORT.has_key?(params[:sort].to_sym)
  end
  
  def sort_direction
    %w[asc desc].include?(params[:direction].to_s) ? params[:direction].to_sym : :desc
  end
  
end
