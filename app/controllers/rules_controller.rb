class RulesController < ApplicationController

  before_filter :require_administrative_privileges, :only => [:compile_rules, :discard_pending_rules]

  # Get all categories and their rules. 
  def index
    @sensor     = Sensor.get(params[:sensor_id]) if params[:sensor_id].present?
    @categories = RuleCategory1.all(:order => [:name.asc])
  end

  # Get last compiled rules for the sensor indicated
  def last_compiled_rules
    @sensor = Sensor.get(params[:sensor_id]) if params[:sensor_id].present?
    @sensor_rules = @sensor.last_compiled_rules
    @sensor_rules = [] if @sensor_rules.nil?

    respond_to do |format|
      format.html {render :layout => true}
      format.text 
    end
  end

  # Method used when the category is showed in the index view. Partial Method
  def update_rule_category
    @sensor = Sensor.get(params[:sensor_id]) if params[:sensor_id].present?
    
    unless params["category_id"].nil?
      @category = RuleCategory1.get(params["category_id"].to_i)
    end

    @groups = RuleCategory2.all()

    @actions             = RuleAction.all
    @pending_rules       = @sensor.pending_rules unless @sensor.nil?
    @last_compiled_rules = @sensor.last_compiled_rules unless @sensor.nil?

    respond_to do |format|
      format.js
    end
  end

  def update_rule_action
    @sensor = Sensor.get(params[:sensor_id].to_i) if params[:sensor_id].present?
    @action = RuleAction.get(params["action_id"].to_i)
    @rule   = Rule.get(params["rule_id"].to_i)

    sr = @sensor.pending_rule?@rule

    if sr.nil?
      sr = @sensor.sensorRules.create(:user => User.current_user, :action => @action, :rule => @rule)
    else
      sr.update(:action => @action)
    end

    respond_to do |format|
      format.js
    end
  end

  def compile_rules
    @sensor = Sensor.get(params[:sensor_id].to_i) if params[:sensor_id].present?
    unless @sensor.nil?
      @sensor.compile_rules
    end
    redirect_to sensor_rules_path(@sensor.sid)
  end

  def discard_pending_rules
    @sensor = Sensor.get(params[:sensor_id].to_i) if params[:sensor_id].present?
    unless @sensor.nil?
      @sensor.discard_pending_rules
    end
    redirect_to sensor_rules_path(@sensor.sid)
  end
  
end
