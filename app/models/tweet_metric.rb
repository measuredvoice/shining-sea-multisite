# == Schema Information
#
# Table name: tweet_metrics
#
#  id            :integer          not null, primary key
#  account_id    :integer
#  tweet_id      :string(255)
#  published_at  :datetime
#  audience      :integer
#  reach         :integer
#  kudos         :integer
#  engagement    :integer
#  tweet_text    :string(255)
#  metrics_ready :boolean          default(FALSE)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class TweetMetric < ActiveRecord::Base
  attr_accessible :tweet_id, :published_at, :audience, :reach, :kudos, :engagement, 
    :tweet_text, :metrics_ready
  
  belongs_to :account
  delegate :twitter_client, :to => :account
  delegate :site, :to => :account
  
  def self.create_from_tweet(tweet)
    self.create(
      :tweet_id      => tweet.id,
      :tweet_text    => tweet.text,
      :published_at  => tweet.created_at,
      :audience      => tweet.user.followers_count,
      :kudos         => tweet.favorite_count,
      :engagement    => tweet.retweet_count,
      :metrics_ready => false,
    )
  end
  
  def self.from_date(target_date)
    where(:published_at => (target_date.beginning_of_day)..(target_date.end_of_day))
  end
  
  def self.ready_to_complete
    where("published_at <= ?", 6.hours.ago)
  end
  
  def self.most_recent
    order(:published_at).last
  end
  
  def id=(value)
    self.tweet_id ||= value
  end
  
  def published_date
    published_at.in_time_zone(site.time_zone).strftime("%Y-%m-%d")
  end
  
  def complete_metrics!(tweet)
    self.kudos = tweet.favorite_count
    self.engagement = tweet.retweet_count
    self.count_reach!
    self.metrics_ready = true
    self.save
  end
  
  def count_reach!
    # Only use expensive API calls if there are retweets to be counted
    if engagement == 0
      self.reach = audience
    else
      begin
        rts = twitter_client.retweeters_of(tweet_id, :count => 100)
        # sleep 15
      rescue Twitter::Error::TooManyRequests => error
        # This was a rate limit issue, so move on
        puts "Rate limit was exceeded."
        return nil
      rescue Exception => error
        puts "Unknown Exception when getting retweets: " + error.inspect
        return nil
      end
        
      self.reach = rts.inject(audience) do |total_reach, retweeter|
        total_reach + retweeter.followers_count
      end
    end
  end
end
