class Snmp

  include DataMapper::Resource
  
  # Included for the truncate helper method.
  extend ActionView::Helpers::TextHelper

  property :id, Serial, :key => true, :index => true

  property :sid, Integer

  property :timestamp, DateTime

  property :oid, String
  
  property :value, Float

  belongs_to :sensor, :parent_key => :sid,
    :child_key => :sid, :required => true
    
    SORT = {
      :sid => 'snmp', 
      :timestamp => 'snmp'
    }
    
  def pretty_time
    return "#{timestamp.strftime('%l:%M %p')}" if Date.today.to_date == timestamp.to_date
    "#{timestamp.strftime('%m/%d/%Y')}"
  end

  def self.get_value(host, oid)
    community = Snorby::CONFIG_SNMP[:community].nil? ? 'public' : Snorby::CONFIG_SNMP[:community]
    manager = SNMP::Manager.new(:Host => host, :community => community)
    # It's not an official SNMP oid
    if oid == "1.3.6.1.4.1.2021.4.5.5"
      response = manager.get("1.3.6.1.4.1.2021.4.6.0")
      value_used = response.varbind_list.first.value
      response = manager.get("1.3.6.1.4.1.2021.4.5.0")
      value_total = response.varbind_list.first.value
      value = (value_used.to_f / value_total.to_f * 100).round(2)
    else
      response = manager.get(oid)
      value = response.varbind_list.first.value
    end
    
    value
  end

  def self.sorty(params={})
    sort = params[:sort]
    direction = params[:direction]

    page = {
      :per_page => User.current_user.per_page_count
    }

    if SORT[sort].downcase == 'snmp'
      page.merge!(:order => sort.send(direction))
    else
      page.merge!(
        :order => [Snmp.send(SORT[sort].to_sym).send(sort).send(direction), 
                   :timestamp.send(direction)],
        :links => [Snmp.relationships[SORT[sort].to_s].inverse]
      )
    end
    
    if params.has_key?(:search)
      page.merge!(search(params[:search]))
    end

    page(params[:page].to_i, page)
  end
  
  def self.last_3_hours(first=nil,last=nil)
    current = Time.now
    end_time = last ? last : current
    start_time = first ? first : current - 3.hours

    all(:timestamp.gte => start_time, :timestamp.lte => end_time)
  end
  
  def self.today
    all(:timestamp.gte => Time.now.beginning_of_day, :timestamp.lte => Time.now.end_of_day)
  end
  
  def self.yesterday
    all(:timestamp.gte => Time.now.yesterday.beginning_of_day, :timestamp.lte => Time.now.yesterday.end_of_day)
  end
  
  def self.this_week
    all(:timestamp.gte => Time.now.beginning_of_week, :timestamp.lte => Time.now.end_of_week)
  end
  
  def self.last_week
    all(:timestamp.gte => (Time.now - 1.week).beginning_of_week, :timestamp.lte => (Time.now - 1.week).end_of_week)  
  end
  
  def self.this_month
    all(:timestamp.gte => Time.now.beginning_of_month, :timestamp.lte => Time.now.end_of_month)  
  end
  
  def self.last_month
    all(:timestamp.gte => (Time.now - 1.months).beginning_of_month, :timestamp.lte => (Time.now - 1.months).end_of_month)  
  end
  
  def self.this_quarter
    all(:timestamp.gte => Time.now.beginning_of_quarter, :timestamp.lte => Time.now.end_of_quarter)  
  end
  
  def self.this_year
    all(:timestamp.gte => Time.now.beginning_of_year, :timestamp.lte => Time.now.end_of_year)  
  end

  def self.cpu_metrics(type=:week)
    @metrics = self.snmp_metrics("1.3.6.1.4.1.2021.11.10.0", type)
  end

  def self.user_cpu_metrics(type=:week)
    @metrics = self.snmp_metrics("1.3.6.1.4.1.2021.11.9.0", type)
  end

  def self.disk_metrics(type=:week)
    @metrics = self.snmp_metrics("1.3.6.1.4.1.2021.9.1.9.1", type)
  end
  
  def self.memory_metrics(type=:week)
    @metrics = self.snmp_metrics("1.3.6.1.4.1.2021.4.5.5", type)
  end
  
  def self.snmp_metrics(oid, type)
    metrics = []

    self.all.sensors.each do |sensor|
      count = []
      time_range = []

      snmp = snmp_for_type(self.all(:oid => oid), type, sensor)

      if snmp.empty?

        range_for_type(type) do |i|
          time_range << "'#{i}'"
          count << 0
        end

      else

        range_for_type(type) do |i|
          time_range << "'#{i}'"

          if snmp.has_key?(i)
            count << (snmp[i].map{|d| d.value.to_f}.sum / snmp[i].count).round(2)
          else
            count << 0
          end

        end

      end

      metrics << { :name => sensor.sensor_name, :data => count, :range => time_range }

    end

    metrics
    
  end
  
  def self.snmp_for_type(collection, type=:week, sensor=false)
    case type.to_sym
    when :last_3_hours
      return collection.group_by { |x| "#{x.timestamp.hour}:#{x.timestamp.min / 10}0" } unless sensor
      return collection.all(:sid => sensor.sid).group_by { |x| "#{x.timestamp.hour}:#{x.timestamp.min / 10}0" }
    when :week, :last_week
      return collection.group_by { |x| x.timestamp.day } unless sensor
      return collection.all(:sid => sensor.sid).group_by { |x| x.timestamp.day }
    when :month, :last_month
      return collection.group_by { |x| x.timestamp.day } unless sensor
      return collection.all(:sid => sensor.sid).group_by { |x| x.timestamp.day }
    when :year, :quarter
      return collection.group_by { |x| x.timestamp.month } unless sensor
      return collection.all(:sid => sensor.sid).group_by { |x| x.timestamp.month }
    else
      return collection.group_by { |x| x.timestamp.hour } unless sensor
      return collection.all(:sid => sensor.sid).group_by { |x| x.timestamp.hour }
    end
  end
  
  def self.range_for_type(type=:week, &block)

    case type.to_sym
      
    when :last_3_hours  
      
      Range.new((Time.now - 3.hours).to_i, Time.now.to_i).step(10.minutes).each do |i|
        block.call("#{Time.at(i).hour}:#{Time.at(i).min / 10}0") if block
      end
      
    when :week

      ((Time.now.beginning_of_week.to_date)..(Time.now.end_of_week.to_date)).to_a.each do |i|
        block.call(i.day) if block
      end

    when :last_week

      (((Time.now - 1.week).beginning_of_week.to_date)..((Time.now - 1.week).end_of_week.to_date)).to_a.each do |i|
        block.call(i.day) if block
      end

    when :month

      ((Time.now.beginning_of_month.to_date)..(Time.now.end_of_month.to_date)).to_a.each do |i|
        block.call(i.day) if block
      end

    when :last_month

      (((Time.now - 1.month).beginning_of_month.to_date)..((Time.now - 1.month).end_of_month.to_date)).to_a.each do |i|
        block.call(i.day) if block
      end

    when :quarter

      ((Time.now.beginning_of_quarter.month)..(Time.now.end_of_quarter.month)).to_a.each do |i|
        block.call(i) if block
      end

    when :year

      Time.now.beginning_of_year.month.upto(Time.now.end_of_year.month) do |i|
        block.call(i) if block
      end

    else

      ((Time.now.beginning_of_day.hour)..(Time.now.end_of_day.hour)).to_a.each do |i|
        block.call(i) if block
      end

    end

  end

  def self.severity_count(severity, type=nil)
    
    count = {}
    
    @snmp = snmp_for_type(self.all(:oid => Snorby::CONFIG_SNMP[:oids].keys), type)

    level_high = Snorby::CONFIG_SNMP[:level_high].to_f
    level_medium = Snorby::CONFIG_SNMP[:level_medium].to_f

    case severity.to_sym

    when :high
      range_for_type(type) do |i|
        if @snmp.has_key?(i)
          count["#{i}"] = @snmp[i].select{|v| v.value.to_f >= level_high}.count
        else
          count["#{i}"] = 0
        end
      end

    when :medium
      range_for_type(type) do |i|
        if @snmp.has_key?(i)
          count["#{i}"] = @snmp[i].select{|v| v.value.to_f < level_high and v.value.to_f >= level_medium}.count
        else
          count["#{i}"] = 0
        end
      end
      
    when :low
      range_for_type(type) do |i|
        if @snmp.has_key?(i)
          count["#{i}"] = @snmp[i].select{|v| v.value.to_f < level_medium}.count
        else
          count["#{i}"] = 0
        end
      end
      
    end

    count.values

  end
  
  def self.search(params)
    
    @search = {}

    @search.merge!({:sid => params[:sid].to_i}) unless params[:sid].blank?
    
    # Severity rating is taken from snmp_config 
    unless params[:severity].blank?
      if params[:severity].to_i == 1
        @search.merge!({:value.gte => Snorby::CONFIG_SNMP[:level_high].to_f})
      elsif params[:severity].to_i == 2
        @search.merge!({:value.gte => Snorby::CONFIG_SNMP[:level_medium].to_f, :value.lt => Snorby::CONFIG_SNMP[:level_high].to_f})
      else
        @search.merge!({:value.lt => Snorby::CONFIG_SNMP[:level_medium].to_f})
      end
    end
  
    # Timestamp
    if params[:timestamp].blank?

      unless params[:time_start].blank? || params[:time_end].blank?
        @search.merge!({
          :conditions => ['timestamp >= ? AND timestamp <= ?',
            Time.at(params[:time_start].to_i),
            Time.at(params[:time_end].to_i)
        ]})
      end

    else

      if params[:timestamp] =~ /\s\-\s/
        start_time, end_time = params[:timestamp].split(' - ')
        @search.merge!({:conditions => ['timestamp >= ? AND timestamp <= ?', 
                       Chronic.parse(start_time).beginning_of_day, 
                       Chronic.parse(end_time).end_of_day]})
      else
        @search.merge!({:conditions => ['timestamp >= ? AND timestamp <= ?', 
                       Chronic.parse(params[:timestamp]).beginning_of_day, 
                       Chronic.parse(params[:timestamp]).end_of_day]})
      end

    end
  
    @search

  rescue NetAddr::ValidationError => e
    {}
  rescue ArgumentError => e
    {}
  
  end

end
