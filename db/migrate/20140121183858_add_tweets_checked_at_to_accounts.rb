class AddTweetsCheckedAtToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :tweets_checked_at, :datetime
    add_index :accounts, [:site_id, :tweets_checked_at]
  end
end
