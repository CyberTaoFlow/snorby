class RuleDbversion

  include DataMapper::Resource
  
  property :id, Serial, :key => true, :index => true
  property :timestamp, DateTime, :index => true, :required => true
  property :completed, Boolean, :default => false

  has n, :rules, :child_key => [ :dbversion_id ], :constraint => :destroy

end
