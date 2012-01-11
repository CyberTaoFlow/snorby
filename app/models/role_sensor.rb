class RoleSensor
  include DataMapper::Resource

  property  :id       , Serial, :key => true, :index => true

  property :sensor_sid, Integer, :index => true
  property :role_id   , Integer, :index => true

  belongs_to :sensor, :parent_key => [ :sid ], :child_key => [ :sensor_sid ]
  belongs_to :role

end