class Sensor
  include DataMapper::Resource

  after :create do |sensor|
    # After the sensor (domain or not) has been created it will involve a rule compilation for this sensor.
    #   This will create an initial restore point and it will inherit all its parents rules
    sensor.compile_rules(nil, sensor.parent.last_compiled_rules) unless sensor.parent.nil? or !sensor.domain
  end

  before :create do |sensor|
    if !domain and parent.nil?
      # After creating one real sensor (domain false) it should be created with the proper virtal sensor parent
      #    The hostname format should be: sensor_name:interface (barnyard2 format)

      pname = /(.+):/.match(sensor.hostname)[1]
      p_sensor = Sensor.first(:name => pname, :domain => true)
      p_sensor = Sensor.create(:name => pname, :domain => true, :parent => Sensor.root) if p_sensor.nil?
      sensor.name = hostname
      sensor.parent = p_sensor
    end
  end

  storage_names[:default] = "sensor"

  property :sid, Serial, :key => true, :index => true

  property :name, String, :default => 'Click To Change Me'

  property :hostname, Text, :index => true

  property :interface, Text

  property :filter, Text

  property :detail, Integer, :index => true

  property :encoding, Integer, :index => true

  property :last_cid, Integer, :index => true

  property :events_count, Integer, :index => true, :default => 0

  property :ipdir, String

  has n, :events, :child_key => :sid, :constraint => :destroy

  has n, :ips, :child_key => :sid, :constraint => :destroy
  
  has n, :notes, :child_key => :sid, :constraint => :destroy
  
  has n, :snmps, :child_key => :sid, :constraint => :destroy

  property :domain, Boolean, :default => false
  
  has n, :childs, self, :constraint => :destroy, :child_key => [ :parent_sid ]

  belongs_to :parent, self, :child_key => [ :parent_sid ], :required => false

  has n, :sensorRules, :constraint => :destroy
  has n, :rules      , :through => :sensorRules

  def cache
    Cache.all(:sid => sid)
  end
  
  def sensor_name
    return name unless name == 'Click To Change Me'
    hostname
  end
  
  def daily_cache
    DailyCache.all(:sid => sid)
  end

  def last
    if domain
      childs.map{|x| x.last}.select{|s| s and s.valid?}.sort{|x, y| y.timestamp <=> x.timestamp}.first unless childs.blank?
    else
      return Event.get(sid, last_cid) unless last_cid.blank?
      false
    end
  end

  def last_pretty_time
    return "#{self.last.timestamp.strftime('%l:%M %p')}" if Date.today.to_date == self.last.timestamp.to_date
    "#{self.last.timestamp.strftime('%m/%d/%Y')}"
  end
  
  def event_percentage
    begin
      total_event_count = Sensor.all.map(&:events_count).sum
      ((self.events_count.to_f / total_event_count.to_f) * 100).round
    rescue FloatDomainError
      0
    end
  end

  # This method will compile the rules saving the pending rules. It will involve the compilation of all sensor included in this domain.

  def compile_rules (compilation=nil, parent_rules=[])
    new_rules = []
    if self.domain
      compilation  = RuleCompilation.create(:timestamp => Time.now, :user => User.current_user) if compilation.nil?
      new_rules    = self.pending_rules
      new_rules_id = new_rules.map{|x| x.rule.id}
      last_compiled_values = self.last_compiled_rules

      new_rules.select{|s| !s.action.nil?}.each{|sr| sr.update(:compilation => compilation)}

      unless last_compiled_values.nil?
        last_compiled_values.select{|x| !x.inherited or parent_rules.blank?}.each do |sr|
          unless new_rules_id.include? sr.rule.id
            new_rules_id << sr.rule.id
            new_rules << SensorRule.create(sr.attributes.merge(:id => nil, :compilation => compilation))
          end
        end
      end

      if parent_rules.blank?
        new_rules.select{|x| x.action.nil?}.each do |sr|
          new_sr = self.parent.nil? ? nil : self.parent.last_compiled_rules.first(:rule => sr.rule)
          if new_sr.nil?
            new_rules_id.delete(sr.rule.id)
            new_rules.delete(sr)
            sr.destroy
          else
            sr.update(:user => new_sr.user, :action => new_sr.action, :inherited => true, :compilation => compilation)
          end
        end
      else
        new_rules.select{|x| x.action.nil?}.each do |sr|
          new_rules_id.delete(sr.rule.id)
          new_rules.delete(sr)
          sr.destroy
        end
      end

      if parent_rules.present?
        parent_rules.each do |pr|
          unless new_rules_id.include? pr.rule.id
            new_rules_id << pr.rule.id
            new_rules << SensorRule.create(pr.attributes.merge(:id => nil, :sensor => self, :compilation => compilation, :inherited => true))
          end
        end
      end
			
      self.childs.each do |s|
        s.compile_rules(compilation, new_rules)
      end		
    end

    new_rules		
  end

  # Returns an array with all pending rules (not compiled). 
  def pending_rules
    sensorRules.all(:compilation => nil)
  end

  # Return the last compilation object for this sensor
  def last_compilation
    RuleCompilation.get(self.sensorRules.map{|x| x.compilation.nil? ? nil : x.compilation.id}.compact.max)
  end

  # Return an array with the rules for the compilation passed as the argument 
  def compiled_rules(compilation_id)
    self.sensorRules.all(:compilation_id => compilation_id)
  end

  # Return an array with the rules for the last compilation (the oldest modifications)
  def last_compiled_rules
    self.compiled_rules(self.last_compilation.id) unless self.last_compilation.nil?
  end

  # This sensor will generate a new compilation with a copy of the rules compiled for the compilation passed. 
  def rollback_rules(compilation)
    if self.domain && !compilation.nil?
      new_compilation = RuleCompilation.create(:timestamp => Time.now, :user => User.current_user)
      self.pending_rules.each{|x| x.destroy}
      compilation.rules.all(:sensor => self).each do |sr|
        SensorRule.create(sr.attributes.merge(:id => nil, :compilation => new_compilation, :user => User.current_user))
      end
      
      self.childs.each do |s|
        s.rollback_rules(compilation)
      end		
    end
  end


  def hierarchy(deep)
    # 'sensors = childs' causes problems instead of 'sensors = childs.map{|x| x}' because of the class DataMapper::Associations::OneToMany::Collection
    sensors = childs.map{|x| x} unless childs.blank? 
		
    if !sensors.nil? and deep > 1 
      sensors.each_with_index do |x, index|
        sensors[index] = [x, x.hierarchy(deep - 1)] unless x.nil? or x.childs.blank?
      end
    end

    sensors
  end

  def events_count
    if domain		
      count = 0			
      childs.each{|x| count += x.events_count}
      count		
    else 
      super
    end
  end

  # Return an array with all real sensors for this sensor.
  def real_sensors
    childs.map{|x| x.domain ? x.real_sensors : x}.flatten.compact unless self.childs.blank?
  end

  def compilations
    sensorRules.compilations
  end

  def discard_pending_rules
    pending_rules.destroy
  end

  def deep
    parent.nil? ? 0 : 1 + parent.deep
  end

  def events
    if domain
      events = Array.new
      childs.each{|x| events << x.events}
      events.flatten
    else
      super
    end
  end		

  # A "virtual sensor" is the first parent of a real sensor
  # A "real sensor" is a sensor with domain property set to false
  #    - it cannot contains other sensor (cannot be parent of other sensor)
  def is_virtual_sensor?
    if domain
      s = childs.first
      if s.nil?
        ret = false
      else
        ret = !s.domain
      end
    else 
      ret = false
    end

    return ret
  end

  # Return the root sensor (first parent)
  def self.root
    Sensor.first(:name => "root")
  end

  def is_root?
    name == 'root'
  end

end
