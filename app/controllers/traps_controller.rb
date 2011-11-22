class TrapsController < ApplicationController
  respond_to :html, :xml, :json, :js, :csv
  
  helper_method :sort_column, :sort_direction  

  def results    
    params[:sort] = sort_column
    params[:direction] = sort_direction

    @traps = Trap.sorty(params)
  end
  
  private
  
  def sort_column
    return :timestamp unless params.has_key?(:sort)
    return params[:sort].to_sym if Trap::SORT.has_key?(params[:sort].to_sym)
  end
  
  def sort_direction
    %w[asc desc].include?(params[:direction].to_s) ? params[:direction].to_sym : :desc
  end

end
