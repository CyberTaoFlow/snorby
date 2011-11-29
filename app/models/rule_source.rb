class RuleSource
  # Rule procedence source. When the script rules2rbIPS is executed it can downloads the rules 
  #     from different sources. This model will represent the procedence of that rule.

  include DataMapper::Resource
  
  property :id, Serial, :key => true, :index => true
  property :name, String, :length => 64, :required => true
  property :description, String, :length => 128
  property :timestamp, DateTime, :index => true
  property :md5, String, :length => 64  

  has n, :rules, :child_key => [ :source_id ], :constraint => :destroy

end
