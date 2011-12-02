class SensorRule
  # Relation between sensors and rules. It represent the rules for activated for each sensor.

  include DataMapper::Resource
  
  # Included for the truncate helper method.
  extend ActionView::Helpers::TextHelper

  property :id       , Serial , :key => true, :index => true
	property :inherited, Boolean, :default => false
 
  belongs_to :sensor     , :model => 'Sensor'         , :child_key => [ :sensor_sid ]
  belongs_to :rule       , :model => 'Rule'           , :child_key => [ :rule_id ]       , :required => true , :index => true
  belongs_to :action     , :model => 'RuleAction'     , :child_key => [ :action_id ]     , :required => false, :index => true
  belongs_to :compilation, :model => 'RuleCompilation', :child_key => [ :compilation_id ], :required => false
  belongs_to :user       , :parent_key => :id         , :child_key => [ :user_id ]

  has n, :comments, :model => 'RuleComment', :child_key => [ :sensorRule_id ]

	def is_pending?
		compilation.nil?
	end
  
end
