class Site < ActiveRecord::Base
  attr_accessible :account_type, :cta_iframe, :explanation, :host_url, :name, 
    :tagline, :time_zone, :tweet_type, :active, :send_congrats, :registry_csv_url, 
    :twitter_client_key, :twitter_client_secret, :twitter_retweeter_key, 
    :twitter_retweeter_secret, :twitter_account_username, :mv_partner_name, 
    :partner_logo_url, :google_analytics_code, :congrats_text 

  validates :name, :presence => true
  
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
