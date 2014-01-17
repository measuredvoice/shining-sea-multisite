module ApplicationHelper

  def date_link(start_date, direction)
    case direction
    when :previous, :prev
      link_date = start_date - 1.day
      dir = 'top'
    when :previous_week
      link_date = start_date - 7.days
      dir = 'weekly'
    when :next
      link_date = start_date + 1.day
      dir = 'top'
    when :next_week
      link_date = start_date + 7.days
      dir = 'weekly'
    end
    
    "<a href=\"/#{dir}/#{link_date.strftime('%Y-%m-%d')}\">#{link_date.strftime('%B %-d, %Y')}</a>"
  end
end
