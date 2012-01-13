class Role
  include DataMapper::Resource

  property  :id         , Serial, :key => true, :index => true
  property  :name       , String, :default => ''
  property  :permission , String, :default => 'read'

  has n, :users, :through => :roleUser
  has n, :sensors, :through => :roleSensor

  has n, :roleSensors
  has n, :roleUsers  

  # constraint => :destroy fails
  before :destroy! do
    self.roleSensors.destroy
    self.roleUsers.destroy
  end

  def sensor_ids
    self.sensors.map{|s| s.sid}
  end

  def sensor_ids=(sensors)
    self.sensors = []
    self.sensors = Sensor.all(:sid => sensors)
    self.save
  end

  def user_ids
    self.users.map{|u| u.id}
  end

  def user_ids=(users)
    self.users = []
    self.users = User.all(:id => users)
    self.save
  end

end