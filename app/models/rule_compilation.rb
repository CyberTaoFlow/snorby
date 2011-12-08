class RuleCompilation
  # Changes applied to one sensor will not be applied to the snort directly until this sensor is compiled
  # Every sensor (domain or not) can be rollback to any compilation time.
  # A compilation of a domain will involve a compilation of each of the sensors contained in the domain

  include DataMapper::Resource
  
  property :id, Serial, :key => true, :index => true
  property :timestamp, DateTime, :index => true, :required => true

  has n, :rules, :model => 'SensorRule', :child_key => [ :compilation_id ], :constraint => :destroy
  
  belongs_to :user, :parent_key => [ :id ], :child_key => [ :user_id ]

  def pretty_timestamp
    timestamp.strftime('%A, %B %d, %Y %I:%M %p')
  end

end
