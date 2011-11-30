class RuleNote

  include DataMapper::Resource

  property :id, Serial, :key => true, :index => true
  property :body, Text, :lazy => true
  timestamps :at

  belongs_to :rule, :parent_key => [ :rule_id ], :child_key => [ :rule_sid ]
  belongs_to :user, :parent_key => [ :id ]     , :child_key => [ :user_id ]

  validates_presence_of :body

end
