class TweetSummary
  include Initializable
  attr_accessor :date, :tweet_id, :screen_name, :account_name, :audience, :reach, :kudos, 
    :engagement, :mv_score, :daily_rank, :daily_pct, :daily_prev, :daily_next, 
    :weekly_rank, :weekly_pct, :weekly_prev, :weekly_next, :embed_html

  def self.from_tweet_metric(account, tweet_metric, date)
    self.new(
      :date         => date,
      :tweet_id     => tweet_metric.tweet_id,
      :screen_name  => account.screen_name,
      :account_name => account.name,
      :audience     => tweet_metric.audience,
      :reach        => tweet_metric.reach,
      :kudos        => tweet_metric.kudos,
      :engagement   => tweet_metric.engagement,
      :mv_score     => calculate_mv_score(tweet_metric),
    )
  end
  
  def filename
    self.class.filename(date, screen_name, tweet_id)
  end
  
  def self.filename(date, screen_name, tweet_id)
    "#{date_path(date)}/#{screen_name}/#{tweet_id}.json"
  end
  
  def self.date_path(date)
    "summary/#{date.strftime('%Y/%m/%d')}"
  end
  
  def self.calculate_mv_score(tweet_metric)
    return 0 if tweet_metric.audience == 0
    ((bayes_alpha + tweet_metric.kudos * 1.5 + tweet_metric.engagement) * 100000 / (bayes_beta + tweet_metric.audience)).to_i
  end
  
  def link
    "https://twitter.com/#{screen_name}" + "/status/#{tweet_id}"  
  end
    
  def our_link
    "http://#{ENV['AWS_BUCKET']}/#{screen_name}/status/#{tweet_id}"  
  end
    
  def determine_pct(tweet_summaries)
    Rank.percentile(self, tweet_summaries) {|ts| ts.mv_score}
  end

  def iso_date
    date.strftime('%Y-%m-%d')
  end

  def to_json
    JSON.pretty_generate(Boxer.ship(:tweet_summary, self, :view => :metrics))
  end

  def filename
    self.class.filename(date, screen_name, tweet_id)
  end
  
  def self.filename(date, screen_name, tweet_id)
    "#{date_path(date)}/#{screen_name}/#{tweet_id}.json"
  end
  
  def self.date_path(date)
    "summaries/#{date.strftime('%Y/%m/%d')}"
  end
  
  def self.bayes_alpha
    ENV['SHINING_SEA_ALPHA'].to_f
  end
  
  def self.bayes_beta
    ENV['SHINING_SEA_BETA'].to_f
  end
end
