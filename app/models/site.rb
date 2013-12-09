class Site < ActiveRecord::Base
  attr_accessible :account_type, :cta_iframe, :explanation, :host_url, :name, 
    :tagline, :time_zone, :tweet_type, :active, :send_congrats, :registry_csv_url, 
    :twitter_client_key, :twitter_client_secret, :twitter_retweeter_key, 
    :twitter_retweeter_secret

  
end
