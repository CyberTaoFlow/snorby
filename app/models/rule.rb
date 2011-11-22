class Rule
  # Version for each rule. Each time the rules2rbIPS script is executed, if it detects new rules it create a new dbversion.
  #    All the rules downloaded will have the same dbversion reference. A rule actualization will involve the script will 
  #    download all rules again creating a new dbversion entry for those rules.

  include DataMapper::Resource
  
  extend ActionView::Helpers::TextHelper

  property :id, Serial, :key => true, :index => true
  property :rule_id, Integer, :index => true, :required => true
  property :protocol, String, :length => 16
  property :l3l4, String, :length => 1024
  property :rev, Integer, :default => 0
  property :rule, String, :length => 2048, :required => true

  belongs_to :category1, :model => 'RuleCategory1', :parent_key => :id, :child_key => :category1_id, :required => true
  belongs_to :category2, :model => 'RuleCategory2', :parent_key => :id, :child_key => :category2_id, :required => true
  belongs_to :dbversion, :model => 'RuleDbversion', :parent_key => :id, :child_key => :dbversion_id, :required => true
  belongs_to :source   , :model => 'RuleSource'   , :parent_key => :id, :child_key => :source_id   , :required => true

  has n, :sensorRules
  has n, :sensors, :model => 'Sensor', :child_key => [ :sid ], :parent_key => [ :rule_id ], :through => :sensorRules

  # array with all versions for one single rule
  def dbversions
    Rule.all(:rule_id => self.rule_id, :source => self.source).map{|x| x.dbversion}.uniq
  end
end
