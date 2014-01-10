# == Schema Information
#
# Table name: accounts
#
#  id          :integer          not null, primary key
#  site_id     :integer
#  screen_name :string(255)
#  user_id     :string(255)
#  name        :string(255)
#  followers   :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Account < ActiveRecord::Base
  attr_accessible :screen_name, :user_id, :name, :followers
  
  belongs_to :site
  
  def self.need_update
    where("accounts.updated_at < ?", 1.day.ago)
  end
  
  def tweets_on(metrics_date)
    day_start = metrics_date.beginning_of_day
    day_end   = metrics_date.end_of_day
    
    # puts "Tweets for #{screen_name} between #{day_start} and #{day_end}..."
    
    begin
      twitter_client.user_timeline(:screen_name => screen_name, :count => 200, :exclude_replies => true, :include_rts => false).find_all do |tweet|
        tweet_date = tweet.created_at.in_time_zone(Time.zone)
        # puts " checking #{tweet_date}..."
        tweet_date >= day_start && tweet_date <= day_end
      end
    rescue Exception => error
      puts "Unknown Exception when listing timeline tweets: " + error.inspect
      return []
    end
  end
  
  def update_from_twitter(twitter_user)
    self.user_id   = twitter_user.id
    self.name      = twitter_user.name
    self.followers = twitter_user.followers_count
    self.save
  end
  
  def twitter_client
    site.twitter_client
  end

  rails_admin do
    list do
      field :screen_name
      field :site
      field :name
      field :followers
    end
  end
end
