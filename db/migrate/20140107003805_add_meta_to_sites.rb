class AddMetaToSites < ActiveRecord::Migration
  def change
    change_table :sites do |t|
      t.string :twitter_account_username
      t.string :mv_partner_name
      t.text :partner_logo_url
      t.string :google_analytics_code
      t.string :congrats_text 
    end
  end
end
