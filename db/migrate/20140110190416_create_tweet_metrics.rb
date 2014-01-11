class CreateTweetMetrics < ActiveRecord::Migration
  def change
    create_table :tweet_metrics do |t|
      t.integer  :account_id
      t.string   :tweet_id
      t.datetime :published_at
      t.integer  :audience
      t.integer  :reach
      t.integer  :kudos
      t.integer  :engagement
      t.string   :tweet_text
      t.boolean  :metrics_ready, :default => false

      t.timestamps
    end
    
    add_index :tweet_metrics, [:account_id, :metrics_ready]
  end
end
