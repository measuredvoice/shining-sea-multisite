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
  
  def pretty_date(date)
    date.to_date.to_s(:long)
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
  
  def link_to_free_trial(site)
    trial_url = "https://app.measuredvoice.com/signup"
    if site.mv_partner_name.present?
      trial_url += "?partner=#{site.mv_partner_name}"
    end
    
    trial_url
  end
  
  
end
