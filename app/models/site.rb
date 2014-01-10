# == Schema Information
#
# Table name: sites
#
#  id                       :integer          not null, primary key
#  name                     :string(255)
#  host_url                 :string(255)
#  registry_csv_url         :text
#  tagline                  :text
#  tweet_type               :string(255)
#  account_type             :string(255)
#  explanation              :text
#  cta_iframe               :text
#  time_zone                :string(255)
#  active                   :boolean          default(FALSE)
#  send_congrats            :boolean          default(FALSE)
#  twitter_client_key       :text
#  twitter_client_secret    :text
#  twitter_retweeter_key    :text
#  twitter_retweeter_secret :text
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  twitter_account_username :string(255)
#  mv_partner_name          :string(255)
#  partner_logo_url         :text
#  google_analytics_code    :string(255)
#  congrats_text            :string(255)
#

class Site < ActiveRecord::Base
  attr_accessible :account_type, :cta_iframe, :explanation, :host_url, :name, 
    :tagline, :time_zone, :tweet_type, :active, :send_congrats, :registry_csv_url, 
    :twitter_client_key, :twitter_client_secret, :twitter_retweeter_key, 
    :twitter_retweeter_secret, :twitter_account_username, :mv_partner_name, 
    :partner_logo_url, :google_analytics_code, :congrats_text 

  validates :name, :presence => true
  
  has_many :accounts

  def self.active
    where(:active => true).order("sites.id")
  end
  
  def self.authorized
    # FIXME: Use an auth_is_valid flag instead
    where("twitter_client_key != '' AND twitter_client_secret != ''").order("sites.id")
  end
  
  def twitter_client
    @twitter_client ||= Twitter::REST::Client.new do |config|
      config.consumer_key        = twitter_client_key
      config.consumer_secret     = twitter_client_secret
      config.access_token        = twitter_retweeter_key
      config.access_token_secret = twitter_retweeter_secret
    end
  end
  
  def update_accounts!
    # TODO: Catch and report errors in the CSV file
    current_accounts = CSV.parse(RestClient.get(registry_csv_url)).map do |row|
      screen_name = row.first
      return nil unless screen_name.present?
      screen_name.gsub(/[^a-zA-Z0-9_]/,'')
    end.find_all {|a| a.present?}
    
    existing_accounts = accounts.map {|a| a.screen_name}
    
    new_accounts = current_accounts - existing_accounts
    puts "Adding accounts: #{new_accounts.inspect}"
    new_accounts.each do |screen_name|
      accounts.create(:screen_name => screen_name)
    end

    old_accounts = existing_accounts - current_accounts
    puts "Removing accounts: #{old_accounts.inspect}"
    old_accounts.each do |screen_name|
      account = accounts.find_by_screen_name(screen_name)
      account.destroy
    end
    
    # Look up the Twitter details for accounts in batches
    accounts_to_update = accounts.need_update.map {|a| a.screen_name} + new_accounts
    
    begin
      twitter_users = twitter_client.users(accounts_to_update)
    rescue Twitter::Error::TooManyRequests => error
      # This was a rate limit issue, pause to let Twitter catch up
      puts "Rate limit was exceeded. Waiting for 5 minutes..."
      sleep 5.minutes
      retry
    rescue Exception => error
      puts "Unknown Exception when getting Twitter user details: " + error.inspect
      twitter_users = []
    end
    
    not_found = accounts_to_update - twitter_users.map {|u| u.screen_name}
    puts "Didn't find these: #{not_found.inspect}"
    
    puts "Updating Twitter details..." 
    twitter_users.each do |user|
      account = accounts.find_by_screen_name(user.screen_name)
      account.update_from_twitter(user)
    end
    
  end

  rails_admin do
    configure :name, :string
    configure :cta_iframe do
      label "CTA iframe"
    end
    configure :partner_logo_url do
      label "Partner logo URL"
    end
    configure :registry_csv_url do
      label "Registry CSV URL"
    end
    configure :mv_partner_name do
      label "MV partner name"
    end
    
    list do
      field :id
      field :name
      field :host_url
      field :twitter_account_username do
        label "Twitter account"
      end
      field :active
      field :send_congrats do
        label "Sending congrats"
      end
    end
    
    edit do
      group :basic_configuration do
        field :name
        field :tagline
        field :tweet_type
        field :account_type
        field :twitter_account_username

        field :explanation
        field :cta_iframe
        field :mv_partner_name
        field :partner_logo_url
      
        field :google_analytics_code
      end
      
      group :autotweeting do
        field :send_congrats
        field :congrats_text
      end
      
      group :twitter_list do
        label "List of Twitter accounts"
        field :registry_csv_url
      end
      
      group :host_time_zone do
        label "Host Name and Time Zone"
        field :host_url
        field :time_zone
        field :active
      end
      
      group :twitter_keys do
        active false
        field :twitter_client_key
        field :twitter_client_secret
        field :twitter_retweeter_key
        field :twitter_retweeter_secret
      end
    end

    show do
      group :basic_configuration do
        field :name
        field :tagline
        field :tweet_type
        field :account_type
        field :twitter_account_username

        field :explanation
        field :cta_iframe
        field :mv_partner_name
        field :partner_logo_url
      
        field :google_analytics_code
      end
      
      group :autotweeting do
        field :send_congrats
        field :congrats_text
      end
      
      group :twitter_list do
        label "List of Twitter accounts"
        field :registry_csv_url
      end
      
      group :host_time_zone do
        label "Host Name and Time Zone"
        field :host_url
        field :time_zone
        field :active
      end
      
      group :twitter_keys do
        field :twitter_client_key
        field :twitter_client_secret
        field :twitter_retweeter_key
        field :twitter_retweeter_secret
      end
    end
  end
end
