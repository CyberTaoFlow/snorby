class RulesController < ApplicationController

  before_filter :require_administrative_privileges, :only => [:compile_rules, :discard_pending_rules]
  skip_before_filter :authenticate_user!, :only => [:active_rules]

  # Get all categories and their rules. 
  def index
    @sensor     = Sensor.get(params[:sensor_id]) if params[:sensor_id].present?
    @categories = RuleCategory4.all(:order => [:name.asc])
    @actions    = RuleAction.all
  end

  # Method used when the category is showed in the index view. Partial Method
  def update_rule_category
    @sensor = Sensor.get(params[:sensor_id]) if params[:sensor_id].present?
    
    unless params["category_id"].nil?
      @category = RuleCategory4.get(params["category_id"].to_i)
    end

    @groups = @category.rules.category1.all(:order => [:name.asc])

    @actions             = RuleAction.all
    @pending_rules       = @sensor.pending_rules unless @sensor.nil?
    @last_compiled_rules = @sensor.last_compiled_rules unless @sensor.nil?

    respond_to do |format|
      format.js
    end
  end

  def update_rule_group
    @sensor   = Sensor.get(params[:sensor_id]) if params[:sensor_id].present?
    @category = RuleCategory4.get(params["category_id"].to_i) unless params["category_id"].nil?
    @group    = RuleCategory1.get(params["group_id"].to_i) unless params["group_id"].nil?
    @families = @category.rules.all(:category1 => @group).category3.all(:order => [:name.asc])
    
    @actions  = RuleAction.all
    @pending_rules = @sensor.pending_rules unless @sensor.nil?
    @last_compiled_rules = @sensor.last_compiled_rules unless @sensor.nil?

    respond_to do |format|
      format.js
    end
  end

  def update_rule_family
    @sensor   = Sensor.get(params[:sensor_id]) if params[:sensor_id].present?
    @category = RuleCategory4.get(params["category_id"].to_i) unless params["category_id"].nil?
    @group    = RuleCategory1.get(params["group_id"].to_i) unless params["group_id"].nil?
    @family   = RuleCategory3.get(params["family_id"].to_i) unless params["family_id"].nil?
    @rules    = @family.rules.all(:category4 => @category, :category1=>@group).all(:order => [:msg.asc])

    @actions  = RuleAction.all
    @pending_rules = @sensor.pending_rules unless @sensor.nil?
    @last_compiled_rules = @sensor.last_compiled_rules unless @sensor.nil?

    respond_to do |format|
      format.js
    end
  end

  def update_rule_details
    @sensor = Sensor.get(params[:sensor_id]) if params[:sensor_id].present?
    @rule = Rule.get(params["rule_id"].to_i) unless params["rule_id"].nil?

    respond_to do |format|
      format.js
    end
  end

  def update_rule_action
    @sensor   = Sensor.get(params[:sensor_id].to_i) if params[:sensor_id].present?
    @action   = RuleAction.get(params[:action_id].to_i) if params[:action_id].present?
    @rule     = Rule.get(params[:rule_id].to_i) if params[:rule_id].present?
    @group    = RuleCategory1.get(params[:group_id].to_i) if params[:group_id].present?
    @category = RuleCategory4.get(params[:category_id].to_i) if params[:category_id].present?

    unless @sensor.nil?
      array = []
      if @group.nil? && @category.nil? && !@rule.nil?
        array << @rule
      elsif !@group.nil? && @category.nil?
        array = @group.rules
      elsif @group.nil? && !@category.nil?
        array = @category.rules
      elsif !@group.nil? && !@category.nil?
        array = Rule.all(:category1_id => @category.id, :category4_id => @group.id)
      end

      Rule.transaction do |t|
        begin
          array.each do |r|
            sr = @sensor.pending_rule?r
            if sr.nil?
              sr = @sensor.sensorRules.create(:user => User.current_user, :action => @action, :rule => r)
            else
              sr.update(:action => @action)
            end
          end
        rescue DataObjects::Error => e
          t.rollback
        end
      end
    end

    respond_to do |format|
      format.js
    end
  end

  def update_rules_action
    @sensor = Sensor.get(params[:sensor_id].to_i) if params[:sensor_id].present?
    @action = RuleAction.get(params[:action_id].to_i) if params[:action_id].present?
    
    @selected_categories = params[:selected_categories] if params[:selected_categories].present?
    @selected_groups     = params[:selected_groups] if params[:selected_groups].present?
    @selected_families   = params[:selected_families] if params[:selected_families].present?
    @selected_rules      = params[:selected_rules] if params[:selected_rules].present?

    unless @sensor.nil?
      array = []

      unless @selected_categories.nil?
        @selected_categories.each do |x|
          ob = RuleCategory4.get(x.to_i)
          unless ob.nil?
            ob.rules.each do |r|
              array << r
            end
          end
        end
      end

      unless @selected_groups.nil?
        @selected_groups.each do |x|
          ob = RuleCategory1.get(x.to_i)
          unless ob.nil?
            ob.rules.each do |r|
              array << r
            end
          end
        end
      end

      unless @selected_families.nil?
        @selected_families.each do |x|
          ob = RuleCategory3.get(x.to_i)
          unless ob.nil?
            ob.rules.each do |r|
              array << r
            end
          end
        end
      end

      unless @selected_categories.nil?
        @selected_categories.each do |x|
          ob = RuleCategory4.get(x.to_i)
          unless ob.nil?
            ob.rules.each do |r|
              array << r
            end
          end
        end
      end

      Rule.transaction do |t|
        begin
          array.each do |r|
            sr = @sensor.pending_rule?r
            if sr.nil?
              sr = @sensor.sensorRules.create(:user => User.current_user, :action => @action, :rule => r)
            else
              sr.update(:action => @action)
            end
          end
        rescue DataObjects::Error => e
          t.rollback
        end
      end
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

  def pending_rules
    respond_to do |format|
      format.html{
        @sensor = Sensor.get(params[:sensor_id])
        @sensor_rules = @sensor.pending_rules.all(:order => [:rule_id.asc]) or []
        @actions = RuleAction.all
        @rulestype = "pending_rules"
      }
      format.text{
        @sensor = Sensor.first(:hostname => params[:sensor_id])
        @sensor_rules = @sensor.last_compiled_rules or []
        @rulestype = "pending_rules"
      }
    end

    respond_to do |format|
      format.html {render :active_rules}
      format.text {render :active_rules}
    end
  end

  # Get last compiled rules for the sensor indicated
  def active_rules
    respond_to do |format|
      format.html{
        @sensor = Sensor.get(params[:sensor_id])
        @sensor_rules = @sensor.last_compiled_rules.all(:order => [:rule_id.asc]) or []
        @actions = RuleAction.all
        @rulestype = "compiled_rules"
      }
      format.text{
        @sensor = Sensor.first(:hostname => params[:sensor_id])
        @sensor_rules = @sensor.last_compiled_rules or []
        @rulestype = "compiled_rules"
      }
    end
  end

  def discard_pending_rules
    @sensor = Sensor.get(params[:sensor_id].to_i) if params[:sensor_id].present?
    unless @sensor.nil?
      @sensor.discard_pending_rules
    end
    redirect_to sensor_rules_path(@sensor.sid)
  end
  
end
