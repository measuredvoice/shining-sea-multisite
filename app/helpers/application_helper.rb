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

  def pretty_number(number)
    number.to_s.reverse.gsub(%r{([[:digit:]]{3})(?=[[:digit:]])(?![[:digit:]]*\.)}, "\\1,").reverse
  end
  
  def pluralize(number, singular, plural)
    if number == 1
      singular
    else
      plural
    end
  end

  def tweet_path(tweet)
    return '' unless tweet
    "/#{tweet.account.screen_name}/status/#{tweet.tweet_id}/"
  end
  
end
