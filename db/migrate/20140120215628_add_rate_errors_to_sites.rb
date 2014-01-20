class AddRateErrorsToSites < ActiveRecord::Migration
  def change
    add_column :sites, :rate_limit_errors, :integer, :default => 0
  end
end
