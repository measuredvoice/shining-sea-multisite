class AddPartnerLinkToSites < ActiveRecord::Migration
  def change
    add_column :sites, :partner_link_url, :text
  end
end
