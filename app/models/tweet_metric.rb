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
#  daily_rank    :integer
#

class TweetMetric < ActiveRecord::Base
  attr_accessible :tweet_id, :published_at, :audience, :reach, :kudos, :engagement, 
    :tweet_text, :metrics_ready, :daily_rank
  
  belongs_to :account
  delegate :twitter_client, :to => :account
  delegate :twitter_app_client, :to => :account
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
    incomplete.where("published_at <= ?", 6.hours.ago).order(:published_at)
  end
  
  def self.most_recent
    order(:published_at).last
  end
  
  def self.incomplete
    where(:metrics_ready => false)
  end
  
  def self.complete
    where(:metrics_ready => true)
  end
  
  def id=(value)
    self.tweet_id ||= value
  end
  
  def published_date
    local_published_at.strftime("%Y-%m-%d")
  end
  
  def local_published_at
    published_at.in_time_zone(site.time_zone)
  end
  
  def complete_metrics!(tweet=nil)
    if tweet.nil?
      begin
        tweet = twitter_client.status(tweet_id)
      rescue Twitter::Error::TooManyRequests => error
        # TODO: Note rate limiting and retry after the rate limit expires
        puts "Rate limit was exceeded while fetching a tweet."
        site.increment!(:rate_limit_errors)
        raise
      rescue Twitter::Error::NotFound => error
        # The tweet was probably deleted
      rescue Twitter::Error => error
        puts "Unknown Twitter error when fetching tweet: " + error.inspect
        raise
      rescue Exception => error
        puts "Unknown Exception when getting tweet: " + error.inspect
        return false
      end      
    end
    
    if tweet.nil?
      self.destroy
      return false
    end
    
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
        # Use application-only auth because the rate limit is higher
        rts = twitter_app_client.retweeters_of(tweet_id, :count => 100)
      rescue Twitter::Error::TooManyRequests => error
        # TODO: Note rate limiting and retry after the rate limit expires
        puts "Rate limit was exceeded while counting reach."
        site.increment!(:rate_limit_errors)
        raise
      rescue Twitter::Error => error
        puts "Unknown Twitter error when counting retweets: " + error.inspect
        raise
      rescue Exception => error
        puts "Unknown Exception when getting retweets: " + error.inspect
        return nil
      end
        
      self.reach = rts.inject(audience) do |total_reach, retweeter|
        total_reach + retweeter.followers_count
      end
    end
  end
  
  def as_summary
    TweetSummary.from_tweet_metric(account, self, local_published_at)
  end

  def mv_score
    return 0 if audience == 0
    ((bayes_alpha + kudos * 1.5 + engagement) * 100000 / 
      (bayes_beta + audience)).to_i
  end
  
  def previous_by_rank
    return nil if daily_rank.blank? || daily_rank < 2
    site.tweet_metrics.from_yesterday.find_by_daily_rank(daily_rank - 1)
  end
  
  def next_by_rank
    return nil if daily_rank.blank?
    site.tweet_metrics.from_yesterday.find_by_daily_rank(daily_rank + 1)
  end
  
  def bayes_alpha
    (ENV['SHINING_SEA_ALPHA'] || '4.84').to_f
  end
  
  def bayes_beta
    (ENV['SHINING_SEA_BETA'] || '44000').to_f
  end
end
