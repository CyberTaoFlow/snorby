class RoleUser
  include DataMapper::Resource

  property :user_id , Integer, :key => true, :index => true
  property :role_id , Integer, :key => true, :index => true

  belongs_to :role     , :model => 'Role'         , :child_key => [ :role_id ]
  belongs_to :user     , :model => 'User'         , :child_key => [ :user_id ]

end
