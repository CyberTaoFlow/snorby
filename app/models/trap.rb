class Trap

  include DataMapper::Resource

  property :id, Serial

  property :sid, Integer, :required => true
  property :ip, String
  property :port, Integer
  property :protocol, String
  property :hostname, String
  property :community, String
  property :message, String, :length => 512
  property :timestamp, DateTime

  belongs_to :sensor, :parent_key => :sid,
    :child_key => :sid, :required => true
  
  SORT = {
    :ip => 'snmp',
    :hostname => 'snmp', 
    :timestamp => 'snmp'
  }
  
  def pretty_time
    return "#{timestamp.strftime('%l:%M %p')}" if Date.today.to_date == timestamp.to_date
    "#{timestamp.strftime('%m/%d/%Y')}"
  end    
  
  def self.sorty(params={})
    sort = params[:sort]
    direction = params[:direction]

    page = {
      :per_page => User.current_user.per_page_count
    }

    if SORT[sort].downcase == 'snmp'
      page.merge!(:order => sort.send(direction))
    else
      page.merge!(
        :order => [Trap.send(SORT[sort].to_sym).send(sort).send(direction), 
                   :timestamp.send(direction)],
        :links => [Trap.relationships[SORT[sort].to_s].inverse]
      )
    end
    
    if params.has_key?(:search)
      page.merge!(search(params[:search]))
    end

    page(params[:page].to_i, page)
  end
  
  def self.search(params)
    
    @search = {}

    unless params[:hostname].blank?
      @search.merge!({:hostname => params[:hostname]})
    end
  
    # Timestamp
    if params[:timestamp].blank?

      unless params[:time_start].blank? || params[:time_end].blank?
        @search.merge!({
          :conditions => ['timestamp >= ? AND timestamp <= ?',
            Time.at(params[:time_start].to_i),
            Time.at(params[:time_end].to_i)
        ]})
      end

    else

      if params[:timestamp] =~ /\s\-\s/
        start_time, end_time = params[:timestamp].split(' - ')
        @search.merge!({:conditions => ['timestamp >= ? AND timestamp <= ?', 
                       Chronic.parse(start_time).beginning_of_day, 
                       Chronic.parse(end_time).end_of_day]})
      else
        @search.merge!({:conditions => ['timestamp >= ? AND timestamp <= ?', 
                       Chronic.parse(params[:timestamp]).beginning_of_day, 
                       Chronic.parse(params[:timestamp]).end_of_day]})
      end

    end
  
    @search

  rescue NetAddr::ValidationError => e
    {}
  rescue ArgumentError => e
    {}
  
  end
  

end
