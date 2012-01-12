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

end