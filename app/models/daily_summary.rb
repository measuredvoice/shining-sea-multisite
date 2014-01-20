class DailySummary
  include Initializable
  attr_accessor :account_summaries, :date, :tweet_summaries
  
  def self.from_metrics(target_date, accounts, tweets)
    summary = self.new(
      :date => target_date,
    )
    
    summary.account_summaries = accounts.map do |account|
      account.as_summary(target_date)
    end
    
    summary.tweet_summaries = tweets.map do |tweet|
      tweet.as_summary
    end
        
    summary
  end
  
  def self.from_json(text)
    puts "Loading daily summary file from JSON..."
    data = MultiJson.load(text, :symbolize_keys => true)
    self.new(
      :date => Time.zone.parse(data[:date]),
      :tweet_summaries => data[:tweets].map { |ts| TweetSummary.new(ts) },
      :account_summaries => data[:accounts].map { |as| AccountSummary.new(as) },      
    )
  end
  
  def self.from_summary_file(target_date)
    s3_obj = s3_bucket.objects[filename(target_date)]
    if s3_obj.exists?
      self.from_json(s3_obj.read)
    else
      nil
    end
  end
          
  def ranked_tweets
    tweet_summaries.sort {|a,b| a.daily_rank <=> b.daily_rank}
  end
  
  def rankings
    DailyRanking.from_summary(self)
  end
  
  def to_json
    JSON.pretty_generate(Boxer.ship(:daily_summary, self))
  end

  def iso_date
    date.strftime('%Y-%m-%d')
  end
  
  def filename
    self.class.filename(date)
  end
  
  def self.filename(date)
    "#{date_path(date)}/daily_summary.json"
  end
  
  def self.date_path(date)
    "summaries/#{date.strftime('%Y/%m/%d')}"
  end
  
end
