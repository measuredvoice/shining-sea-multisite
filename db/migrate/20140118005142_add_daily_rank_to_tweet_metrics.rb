class AddDailyRankToTweetMetrics < ActiveRecord::Migration
  def change
    add_column :tweet_metrics, :daily_rank, :integer
    add_index  :tweet_metrics, :daily_rank
  end
end
