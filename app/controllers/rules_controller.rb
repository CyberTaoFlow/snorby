class RulesController < ApplicationController

  # Get all categories and their rules. 
	def index
		@sensor = Sensor.get(params[:sensor_id]) if params[:sensor_id].present?
		@categories = RuleCategory2.all(:order => [:name.asc])
	end

  # Get last compiled rules for the sensor indicated
  def last_compiled_rules
    @sensor = Sensor.get(params[:sensor_id]) if params[:sensor_id].present?
    @sensor_rules  = @sensor.last_compiled_rules

    respond_to do |format|
      format.html {render :layout => true}
      format.text 
    end
  end

  # Method used when the category is showed in the index view. Partial Method
  def update_rule_category
    @sensor = Sensor.get(params[:sensor_id]) if params[:sensor_id].present?
    
    unless params["category_id"].nil?
      @category = RuleCategory2.get(params["category_id"].to_i)
    end
  end

end
