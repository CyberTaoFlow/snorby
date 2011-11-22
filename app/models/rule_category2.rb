class RuleCategory2
  # Category2s for each rule. The category2 represent the class-type include in the rule message 
  #   Example: 
  #      - alert tcp $EXTERNAL_NET any -> $HOME_NET 21 (msg:"ETPRO FTP ..."; ... classtype:attempted-admin; sid:2800594; rev:2;) 
  #           -> "attempted-admin"

  include DataMapper::Resource
  
  property :id, Serial, :key => true, :index => true
  property :name, String, :length => 64, :required => true
  property :description, String, :length => 128

  has n, :rules, :child_key => [ :category2_id ], :constraint => :destroy

end
