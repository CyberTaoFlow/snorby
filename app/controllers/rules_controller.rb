class RulesController < ApplicationController

  before_filter :require_administrative_privileges, :only => [:compile_rules, :discard_pending_rules]
  skip_before_filter :authenticate_user!, :only => [:active_rules, :preprocessors_rules]

  # Get all categories and their rules. 
  def index
    @sensor     = Sensor.get(params[:sensor_id]) if params[:sensor_id].present?
    @categories = RuleCategory4.all(:order => [:name.asc])
    @actions    = RuleAction.all
  end

  def show
    if params["rule_id"].nil? && params["rev"].nil?
      @rule = Rule.get(params["id"].to_i) unless params["id"].nil?
    else
      @rule = Rule.last(:rule_id=>params["id"].to_i, :gid=>params["gid"].to_i, :rev=>params["rev"].to_i)
    end

    respond_to do |format|
      format.html { render :layout => false }
    end
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
    @category = RuleCategory4.get(params[:category_id].to_i) if params[:category_id].present?
    @group    = RuleCategory1.get(params[:group_id].to_i) if params[:group_id].present?
    @family   = RuleCategory3.get(params[:family_id].to_i) if params[:family_id].present?
    @rule     = Rule.get(params[:rule_id].to_i) if params[:rule_id].present?
    
    if !@sensor.nil? 
      if !@rule.nil?
        rules = [@rule]
      elsif !@category.nil? && !@group.nil? && @family.nil?
        rules = Rule.all(:category4_id => @category.id, :category1_id => @group.id)
      elsif !@category.nil? && !@group.nil? && !@family.nil?
        rules = Rule.all(:category4_id => @category.id, :category1_id => @group.id, :category3_id => @family.id)
      elsif !@category.nil? && @group.nil? && @family.nil?
        rules = @category.rules
      elsif @category.nil? && @group.nil? && !@family.nil?
        rules = @family.rules
      elsif @category.nil? && !@group.nil? && @family.nil?
        rules = @group.rules
      elsif !@category.nil? && @group.nil? && !@family.nil?
        rules = Rule.all(:category3_id => @family.id, :category4_id => @category.id)
      elsif @category.nil? && !@group.nil? && !@family.nil?
        rules = Rule.all(:category3_id => @family.id, :category1_id => @group.id)
      end

      Rule.transaction do |t|
        begin
          (rules or []).each do |r|
            sr = @sensor.pending_rule? (r)
            sr ||= @sensor.sensorRules.create(:user => User.current_user, :rule => r)
            sr.update(:action => @action)
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
      rules = []

      unless @selected_categories.nil?
        @selected_categories.each do |x|
          ob = RuleCategory4.get(x.to_i)
          unless ob.nil?
            ob.rules.each do |r|
              rules << r
            end
          end
        end
      end

      unless @selected_groups.nil?
        @selected_groups.each do |x|
          ob = RuleCategory1.get(x.to_i)
          unless ob.nil?
            ob.rules.each do |r|
              rules << r
            end
          end
        end
      end

      unless @selected_families.nil?
        @selected_families.each do |x|
          ob = RuleCategory3.get(x.to_i)
          unless ob.nil?
            ob.rules.each do |r|
              rules << r
            end
          end
        end
      end

      unless @selected_categories.nil?
        @selected_categories.each do |x|
          ob = RuleCategory4.get(x.to_i)
          unless ob.nil?
            ob.rules.each do |r|
              rules << r
            end
          end
        end
      end

      Rule.transaction do |t|
        begin
          rules.each do |r|
            sr = @sensor.pending_rule? (r)
            sr ||= @sensor.sensorRules.create(:user => User.current_user, :rule => r)
            sr.update(:action => @action)
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
    @sensor = Sensor.get(params[:sensor_id])
    @sensor_rules = @sensor.pending_rules.all(:order => [:rule_id.asc]) or []
    @actions = RuleAction.all
    @rulestype = "pending_rules"
    @sensor_rules = @sensor_rules.page(params[:page].to_i, :per_page => User.current_user.per_page_count)
    render :active_rules
  end

  # Get last compiled rules for the sensor indicated
  def active_rules
    respond_to do |format|
      format.html{
        @sensor = Sensor.get(params[:sensor_id])
        @sensor_rules = @sensor.last_compiled_rules
        @actions = RuleAction.all
        @rulestype = "compiled_rules"
        @sensor_rules = @sensor_rules.page(params[:page].to_i, :per_page => User.current_user.per_page_count) unless @sensor_rules.blank?
      }
      format.js{
        @sensor = Sensor.get(params[:sensor_id])
        @sensor_rules = @sensor.last_compiled_rules
        @actions = RuleAction.all
        @rulestype = "compiled_rules"
        @sensor_rules = @sensor_rules.page(params[:page].to_i, :per_page => User.current_user.per_page_count) unless @sensor_rules.blank?
      }
      format.text{
        @sensor = Sensor.first(:hostname => params[:sensor_id])
        @sensor_rules = @sensor.last_compiled_rules
        preprocessors_id = RuleCategory4.preprocessors.id
        @sensor_rules = @sensor_rules.select{|x| x.rule.category4_id != preprocessors_id} unless @sensor_rules.blank?
        @rulestype = "compiled_rules"
      }
    end
  end

  def preprocessors_rules
    respond_to do |format|
      format.text{
        @sensor = Sensor.first(:hostname => params[:sensor_id])
        @sensor_rules = @sensor.last_compiled_rules
        preprocessors_id = RuleCategory4.preprocessors.id
        @sensor_rules = @sensor_rules.select{|x| x.rule.category4_id == preprocessors_id} unless @sensor_rules.blank?
        @rulestype = "preprocessors_rules"
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
  
  def compilations
    @sensor = Sensor.get(params[:sensor_id])
    if @sensor.last_compilation.present?
      @compilations = @sensor.sensorRules.compilation.all(:id.lt => @sensor.last_compilation.id, :order => [:timestamp.desc])
    else
      @compilations = []
    end
    
    render :layout => false
  end
  
  def rollback
    @sensor = Sensor.get(params[:sensor][:sid])
    @sensor.rollback_rules(RuleCompilation.get(params[:compilation]))
    redirect_to active_rules_sensor_rules_path(@sensor.sid)
  end
  
end
