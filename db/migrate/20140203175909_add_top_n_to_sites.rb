class AddTopNToSites < ActiveRecord::Migration
  def change
    add_column :sites, :top_tweets_limit, :integer, :default => 50
  end
end
