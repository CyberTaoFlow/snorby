class RoleSensor
  include DataMapper::Resource

  property :sensor_sid, Integer, :key => true, :index => true
  property :role_id   , Integer, :key => true, :index => true

  belongs_to :sensor, :model => 'Sensor', :child_key => [ :sensor_sid ]
  belongs_to :role  , :model => 'Role'  , :child_key => [ :role_id ]

end