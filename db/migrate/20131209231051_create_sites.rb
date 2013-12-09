class CreateSites < ActiveRecord::Migration
  def change
    create_table :sites do |t|
      t.string :name
      t.string :host_url
      t.text :registry_csv_url
      t.text :tagline
      t.string :tweet_type
      t.string :account_type
      t.text :explanation
      t.text :cta_iframe
      t.string :time_zone
      t.boolean :active, :default => :false
      t.boolean :send_congrats, :default => :false
      t.text :twitter_client_key
      t.text :twitter_client_secret
      t.text :twitter_retweeter_key
      t.text :twitter_retweeter_secret

      t.timestamps
    end
    
    add_index :sites, :host_url
    add_index :sites, :active
  end
end
