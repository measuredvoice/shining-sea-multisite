class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.integer :site_id
      t.string :screen_name
      t.string :user_id
      t.string :name
      t.integer :followers

      t.timestamps
    end
    
    add_index :accounts, [:site_id, :screen_name]
  end
end
