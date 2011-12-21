class Sensor
  include DataMapper::Resource

  after :create do |sensor|
    # After the sensor (domain or not) has been created it will involve a rule compilation for this sensor.
    #   This will create an initial restore point and it will inherit all its parents rules
    sensor.compile_rules(nil, sensor.parent.last_compiled_rules) unless sensor.parent.nil? or !sensor.domain
    
    #we must create a new role for chef
    sensor.create_chef_sensor
  end

  after :update do |sensor|
    sensor.update_chef_sensor
  end

  after :destroy do |sensor|
    if sensor.domain
      role = sensor.chef_role
      role.destroy unless role.nil?
    end
  end

  storage_names[:default] = "sensor"

  property :sid, Serial, :key => true, :index => true

  property :name, String, :default => ''

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
    return name unless (name.nil? or name == '')
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

      new_rules.select{|s| !s.action.nil? and !s.action.inherited?}.each{|sr| sr.update(:compilation => compilation)}

      unless last_compiled_values.nil?
        last_compiled_values.select{|x| !x.inherited or parent_rules.blank?}.each do |sr|
          unless new_rules_id.include? sr.rule.id
            new_rules_id << sr.rule.id
            new_rules << SensorRule.create(sr.attributes.merge(:id => nil, :compilation => compilation))
          end
        end
      end

      if parent_rules.blank?
        new_rules.select{|x| x.action.nil? or x.action.inherited?}.each do |sr|
          new_sr = (self.parent.nil? or self.parent.last_compiled_rules.blank?) ? nil : self.parent.last_compiled_rules.first(:rule => sr.rule)
          if new_sr.nil?
            new_rules_id.delete(sr.rule.id)
            new_rules.delete(sr)
            sr.destroy
          else
            sr.update(:user => new_sr.user, :action => new_sr.action, :inherited => true, :compilation => compilation)
          end
        end
      else
        new_rules.select{|x| x.action.nil? or x.action.inherited?}.each do |sr|
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
    self.sensorRules.all(:compilation_id => compilation_id, :order => [:rule_id.asc])
  end

  # Return an array with the rules for the last compilation (the oldest modifications)
  def last_compiled_rules
    self.last_compilation.nil? ? [] : self.compiled_rules(self.last_compilation.id)
  end

  def rollback_last_rules(index=1)
    c = self.compilations
    unless c.nil?
      if c.size>index
        rollback_rules(c[c.size-index-1])
      end
    end
  end

  # This sensor will generate a new compilation with a copy of the rules compiled for the compilation passed. 
  def rollback_rules(compilation)
    if self.domain && !compilation.nil?
      SensorRule.transaction do |t|
        begin
          new_compilation = RuleCompilation.create(:timestamp => Time.now, :user => User.current_user)
          self.pending_rules.each{|x| x.destroy}
          compilation.rules.all(:sensor => self).each do |sr|
            SensorRule.create(sr.attributes.merge(:id => nil, :compilation => new_compilation, :user => User.current_user))
          end

          self.childs.each do |s|
            s.rollback_rules(compilation)
          end
        rescue DataObjects::Error => e
          t.rollback
        end
      end
    end
  end

  def hierarchy(deep)
    # 'sensors = childs' causes problems instead of 'sensors = childs.map{|x| x}' because of the class DataMapper::Associations::OneToMany::Collection
    sensors = childs.all(:order => [:name.asc]).map{|x| x} unless childs.blank?
		
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
    (childs.map{|x| x.domain ? x.real_sensors : x}.flatten.compact unless self.childs.blank?) or []
  end

  # Return an array with all childs virtual sensors for this sensor, including self sensor.
  def virtual_sensors
    sensors = childs.map do |x|
      if x.is_virtual_sensor?
        x
      elsif x.domain
        x.virtual_sensors
      end
    end

    sensors << self if self.is_virtual_sensor?

    sensors.flatten.compact

  end

  def compilations
    sensorRules.compilations
  end

  def deep
    parent.nil? ? 0 : 1 + parent.deep
  end

  # Args is used for accept arguments like sensor.events(:timestamp.gte => Time.now.yesterday)
  def events(args={})
    if domain
      Event.all(args.merge!(:sid => real_sensors.map{|x| x.sid}))
    else
      super(args)
    end
  end

  # A "virtual sensor" is the first parent of a real sensor
  # A "real sensor" is a sensor with domain property set to false
  #    - it cannot contains other sensor (cannot be parent of other sensor)
  def is_virtual_sensor?
    domain and childs.present? and childs.select{|x| x.domain}.empty?
  end

  # Return the root sensor (first parent)
  def self.root
    Sensor.first(:name => "root")
  end

  def is_root?
    parent.nil? and self.name == 'root'
  end

  # Return nil if this rule is not pending.
  # In case this rule is pending it will return the sensorRule asociated
  def pending_rule?(rule)
    self.pending_rules.first(:rule => rule)
  end

  def discard_pending_rules
    SensorRule.transaction do |t|
      begin
        pending_rules.destroy
      rescue DataObjects::Error => e
        t.rollback
      end
    end
  end

  def action_for_rule(rule)
    sr     = self.pending_rules.first(:rule_id => rule.id)
    action = nil

    if sr.nil?
      lcr = self.last_compiled_rules
      unless lcr.empty?
        sr = lcr.first(:rule_id => rule.id)
        action = sr.action unless sr.nil?
      end
    else
      action = sr.action
    end    
    action
  end

  def chef_name
    if domain
      "rBsensor-#{self.sid}"
    else
      self.parent.chef_name
    end
  end

  def chef_role
    Chef::Role.load(self.chef_name)
  end

  def chef_node
    if self.is_virtual_sensor?
      Chef::Node.load(self.hostname)
    end
  end

  def create_chef_sensor
    if self.domain
      role = Chef::Role.new
      set_default_chef_role_params(role)
      role.create
    end
  end

  def update_chef_sensor
    if self.domain
      role = self.chef_role
      set_default_chef_role_params(role)
      role.save

      if self.is_virtual_sensor?
        #we have to update the node
        node = self.chef_node
        unless node.nil?
          node.run_list("role[#{self.chef_name}]")
          node.save
        end
      end
    end
  end

  def destroy_chef_role
    if self.domain
      if self.is_virtual_sensor?
        node = self.chef_node
        node.destroy unless node.nil?
      end

      role = self.chef_role
      role.destroy unless role.nil?
    end
  end

  def self.repair_chef_db
    Sensor.all(:domain=>true).each do |sensor|
      begin
        sensor.update_chef_sensor
      rescue Net::HTTPServerException
        sensor.create_chef_sensor
      end
    end

    Chef::Role.list.each do |array|
      match = /^rBsensor-([0-9]+)$/.match(array[0])
      unless match.nil?
        sensor = Sensor.get(match[1])
        sensor = nil if !sensor.nil? && !sensor.domain
        
        if sensor.nil?
          Chef::Role.load(array[0]).destroy
        end
      end
    end
  end

  private

  def set_default_chef_role_params(role)
    unless role.nil?
      role.name(self.chef_name)
      role.description(self.sensor_name)
      role.override_attributes["redBorder"] = {} if role.override_attributes["redBorder"].nil?
      role.override_attributes["redBorder"][:role]  = role.name
      role.override_attributes["redBorder"][:snort] = {} if role.override_attributes["redBorder"][:snort].nil?
      if self.parent.nil? or self.is_root?
        role.run_list("role[sensor]")
      else
        role.run_list("role[#{self.parent.chef_name}]")
      end
    end
  end
  
end
