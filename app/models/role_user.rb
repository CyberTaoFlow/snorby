class RoleUser
  include DataMapper::Resource

  property :id     , Serial, :key => true, :index => true

  property :user_id, Integer, :index => true
  property :role_id, Integer, :index => true

  belongs_to :role
  belongs_to :user

end
