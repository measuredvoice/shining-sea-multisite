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
  delegate :twitter_client, :to => :site
  delegate :time_zone_obj, :to => :site
  
  has_many :tweet_metrics do
    def from_yesterday
      account = proxy_association.owner
      yesterday = account.time_zone_obj.now - 1.day
      from_date(yesterday)
    end
  end
  
  def self.need_update
    where("accounts.updated_at < ?", 1.day.ago)
  end
  
  def tweets_on(metrics_date)
    day_start = metrics_date.beginning_of_day
    day_end   = metrics_date.end_of_day
    
    # puts "Tweets for #{screen_name} between #{day_start} and #{day_end}..."
    timeline_options = {
      :screen_name     => screen_name, 
      :count           => 200, 
      :exclude_replies => true, 
      :include_rts     => false,
    }
    
    begin
      twitter_client.user_timeline(timeline_options).find_all do |tweet|
        tweet_date = tweet.created_at.in_time_zone(site.time_zone)
        # puts " checking #{tweet_date}..."
        tweet_date >= day_start && tweet_date <= day_end
      end
    rescue Exception => error
      puts "Unknown Exception when listing timeline tweets: " + error.inspect
      return []
    end
  end
  
  def recent_tweets
    # puts "Tweets for #{screen_name} between #{day_start} and #{day_end}..."
    timeline_options = {
      :screen_name     => screen_name, 
      :count           => 200, 
      :exclude_replies => true, 
      :include_rts     => false,
    }
    
    # Start from the newest tweet we already know
    if tm = tweet_metrics.most_recent
      timeline_options[:since_id] = tm.tweet_id
    end
    
    begin
      twitter_client.user_timeline(timeline_options).find_all do |tweet|
        tweet_date = tweet.created_at.in_time_zone(site.time_zone)
        # puts " checking #{tweet_date}..."
        tweet_date >= 1.day.ago
      end
    rescue Twitter::Error::TooManyRequests => error
      # TODO: Note rate limiting and retry after the rate limit expires
      puts "Rate limit was exceeded."
      return nil
    rescue Exception => error
      puts "Unknown Exception when listing timeline tweets: " + error.inspect
      return []
    end
  end
  
  def fetch_recent_tweets!
    recent_tweets.each do |tweet|
      # If we already know this tweet, skip it.
      # NOTE: The Twitter gem returns an integer for the ID; we store it as a string.
      next if tm = tweet_metrics.find_by_tweet_id(tweet.id.to_s)
      
      tm = tweet_metrics.create_from_tweet(tweet)
    end
  end
    
  def update_from_twitter(twitter_user)
    self.user_id   = twitter_user.id
    self.name      = twitter_user.name
    self.followers = twitter_user.followers_count
    self.save
  end
  
  def date_start(target_date)
    site.time_zone_obj.now.beginning_of_day - 1.day
  end
  
  def date_end(target_date)
    yesterday_start.end_of_day
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
