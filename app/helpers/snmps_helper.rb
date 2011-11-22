module SnmpsHelper
  
  def time_range_title(type)

    title = case type.to_sym
    when :last_3_hours
      %{
        #{(@now - 3.hours).strftime('%D %H:%M')}
        -
        #{@now.strftime('%D %H:%M')}
      }
    when :today
      "#{@now.strftime('%A, %B %d, %Y')}"
    when :yesterday
      "#{@now.yesterday.strftime('%A, %B %d, %Y')}"
    when :week
      %{
        #{@now.beginning_of_week.strftime('%D')}
        -
        #{@now.end_of_week.strftime('%D')}
      }
    when :month
      "#{@now.beginning_of_month.strftime('%B')}"
    when :quarter
      %{
        #{@now.beginning_of_quarter.strftime('%B %Y')}
        -
        #{@now.end_of_quarter.strftime('%B %Y')}
      }
    when :year
      "#{@now.strftime('%Y')}"
    else
      ""
    end
    
    title

  end
  
end
