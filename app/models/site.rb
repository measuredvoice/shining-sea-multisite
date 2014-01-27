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
#  rate_limit_errors        :integer          default(0)
#  partner_link_url         :text
#

class Site < ActiveRecord::Base
  attr_accessible :account_type, :cta_iframe, :explanation, :host_url, :name, 
    :tagline, :time_zone, :tweet_type, :active, :send_congrats, :registry_csv_url, 
    :twitter_client_key, :twitter_client_secret, :twitter_retweeter_key, 
    :twitter_retweeter_secret, :twitter_account_username, :mv_partner_name, 
    :partner_logo_url, :partner_link_url, :google_analytics_code, :congrats_text 

  validates :name, :presence => true
  
  has_many :accounts
  
  has_many :tweet_metrics, :through => :accounts do
    def from_yesterday
      account = proxy_association.owner
      yesterday = account.time_zone_obj.now - 1.day
      from_date(yesterday)
    end
  end
  
  after_save :check_for_accounts

  def self.active
    where(:active => true).order("sites.id")
  end
  
  def self.authorized
    # FIXME: Use an auth_is_valid flag instead
    where("twitter_client_key != '' AND twitter_client_secret != ''").order("sites.id")
  end
  
  def self.in_hour(target_hour)
    all.find_all {|site| site.current_hour == target_hour}
  end
    
  def twitter_client
    @twitter_client ||= Twitter::REST::Client.new do |config|
      config.consumer_key        = twitter_client_key
      config.consumer_secret     = twitter_client_secret
      config.access_token        = twitter_retweeter_key
      config.access_token_secret = twitter_retweeter_secret
    end
  end
  
  def twitter_app_client
    @twitter_app_client ||= Twitter::REST::Client.new do |config|
      config.consumer_key        = twitter_client_key
      config.consumer_secret     = twitter_client_secret
    end
  end
  
  def twitter_account_full_username
    return nil if twitter_account_username.empty?
    twitter_account_username.gsub(/^@?/, '@')
  end
  
  def twitter_account_base_username
    return nil if twitter_account_username.empty?
    twitter_account_username.gsub(/^@/, '')
  end
  
  def current_hour
    time_zone_obj.nil? ? nil : time_zone_obj.now.strftime('%H').to_i
  end
  
  def rate_per_hour_for(the_method)
    rate_per_minute_for(the_method) * 60
  end
  
  def rate_per_minute_for(the_method)
    case the_method
    when :fetch_recent_tweets
      # per https://dev.twitter.com/docs/api/1.1/get/statuses/user_timeline
      12
    when :complete_metrics
      # per https://dev.twitter.com/docs/api/1.1/get/statuses/show/%3Aid
      # and https://dev.twitter.com/docs/api/1.1/get/statuses/retweeters/ids
      # (uses application-only authentication for retweeters)
      4
    end
  end
  
  def queue_time_for(queue_position, the_method)
    (queue_position / rate_per_minute_for(the_method)).minutes.from_now
  end
  
  def reset_rate_limit_errors!
    self.rate_limit_errors = 0
    self.save!
  end
  
  def ready_to_publish?
    s3_is_configured? && dns_is_configured?
  end
  
  def prepare_for_publishing!
    unless s3_is_configured?
      configure_s3
    end
    unless dns_is_configured?
      configure_dns
    end
  end
  
  def s3_is_configured?
    return false if host_url.blank?
    
    s3_bucket.exists? && s3_bucket.website_configuration.present?
  end
  
  def configure_s3
    return false if host_url.blank?
    
    # Create the bucket. (Will return an existing bucket if already created.)
    bucket = AWS::S3.new.buckets.create(host_url)
    
    # Allow the bucket to be served as a website.
    # (Will update the configuration if already configured.)
    bucket.configure_website do |cfg|
      cfg.error_document_key = 'assets/errors/404.html'
    end
    
    # Add a site policy to allow public access.
    # The AWS gem's policy generator doesn't quite work, so build JSON.
    json_policy =     
      {
        "Version" => "2008-10-17",
        "Statement" => [
          {
            "Sid" => "AllowPublicRead",
            "Effect" => "Allow",
            "Principal" => {
              "AWS" => "*"
            },
            "Action" => "s3:GetObject",
            "Resource" => "arn:aws:s3:::#{host_url}/*"
          }
        ]
      }.to_json
    bucket.policy = json_policy
  end
  
  def s3_bucket
    AWS::S3.new.buckets[host_url]
  end
    
  def dns_is_configured?
    dns_record = fetch_dns_record
    return false if dns_record.blank?
    
    # The record should point to an "S3 website" generic host.
    alias_target = dns_record[:alias_target]
    return false if alias_target.blank?
    
    alias_host = alias_target[:dns_name]
    if alias_host.present? && alias_host =~ /^s3-website/
      return true
    end
    
    false
  end
  
  def configure_dns
    if host_url.blank?
      logger.info "Can't configure DNS for #{site.name} until a host URL is specified."
      return false
    end
    
    if dns_record_exists?
      if dns_is_configured?
        return true
      else
        logger.info "Can't configure DNS for #{site.name}; #{host_url} already exists."
        return false
      end
    end
      
    # NOTE: The AWS Ruby client only supports a low-level interface as of 1.32.0.
    #   When the gem provides native objects, use those instead.
    response = dns_client.change_resource_record_sets(
      :hosted_zone_id => ENV['AWS_DNS_ZONE_ID'],
      :change_batch => {
        :changes => [{
          :action => "CREATE",
          :resource_record_set => {
            :name => host_dns_name,
            :type => "A",
            :alias_target => {
              :hosted_zone_id => ENV['AWS_REGION_ZONE_ID'],
              :dns_name => "s3-website-#{ENV['AWS_REGION']}.amazonaws.com.",
              :evaluate_target_health => false,
            },
          },
        }],
      },
    )
    
    response[:change_info][:id].present?
  end
    
  def dns_client
    @dns_client ||= AWS::Route53.new.client
  end
  
  def fetch_dns_record
    return nil unless host_dns_name
    
    # NOTE: The AWS Ruby client only supports a low-level interface as of 1.32.0.
    #   When the gem provides native objects, use those instead.
    response = dns_client.list_resource_record_sets(
      :hosted_zone_id    => ENV['AWS_DNS_ZONE_ID'], 
      :start_record_name => host_dns_name, 
      :start_record_type => 'A', 
      :max_items         => 1
    )
    
    # AWS will return either the record set we asked for, the one alphabetically after it,
    # or an empty record set list.
    dns_record = response[:resource_record_sets].first
    return nil if dns_record.blank? || dns_record[:name] != host_dns_name
    
    dns_record
  end
  
  def dns_record_exists?
    fetch_dns_record.present?
  end
  
  def host_dns_name
    host_url.present? ? "#{host_url}." : nil
  end

  def time_zone_obj
    ActiveSupport::TimeZone.new(time_zone)
  end
  
  def check_for_accounts
    if active? && registry_csv_url.present? && accounts.count == 0
      delay.update_accounts!
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
      account.update_from_twitter(user) if account.present?
    end
  end
  
  def clear_old_tweet_metrics!
    tweet_metrics.where("published_at < ?", 7.days.ago).each do |tm|
      tm.destroy
    end
  end

  def write_summary_to_s3(summary)
    puts "  Writing #{summary.filename} to S3..."
    s3_bucket.objects[summary.filename].write(summary.to_json)
  end
  
  def summary_written_to_s3?(summary)
    s3_bucket.objects[summary.filename].exists?
  end
  
  def ranked_tweets_for(target_date)
    tweet_metrics.from_date(target_date).complete.includes(:account).order(:daily_rank)
  end
  
  def set_tweet_ranks!(target_date)
    tweet_metrics.from_date(target_date).complete.sort do |a,b|
      b.mv_score <=> a.mv_score
    end.each_with_index do |tweet_metric, index|
      tweet_metric.daily_rank = index + 1
      tweet_metric.save
    end
  end
  
  def write_final_metrics_for(target_date)
    tweets = ranked_tweets_for(target_date)
    tweets.each do |tweet|
      write_summary_to_s3(tweet.as_summary)
    end
    
    accounts.each do |account|
      summary = account.as_summary(target_date)
      summary.tweet_summaries = tweets.find_all do |tm|
        tm.account == account
      end.map {|tm| tm.as_summary}
      write_summary_to_s3(summary)
    end 
    
    ds = DailySummary.from_metrics(target_date, accounts, tweets)
    write_summary_to_s3(ds)
    write_summary_to_s3(ds.rankings)
  end
  
  def html_files_to_publish_for(target_date)
    files_to_publish = []
    
    # First, write files for the individual tweets.
    ranked_tweets_for(target_date).each do |tweet|
      files_to_publish << {
        :filename => "#{tweet.account.screen_name}/status/#{tweet.tweet_id}/index.html",
        :route => "site/#{id}/#{tweet.account.screen_name}/status/#{tweet.tweet_id}",
      }
    end
    
    # Next, write the dated version of the index file.
    files_to_publish << {
      :filename => "top/#{target_date.strftime('%Y-%m-%d')}/index.html",
      :route => "site/#{id}?target_date=#{target_date.strftime('%Y-%m-%d')}",
    }
    
    # Next, write the updated iframe file.
    files_to_publish << {
      :filename => "iframes/#{id}/index.html",
      :route => "iframes/#{id}",
    }

    # Finally, write the main index file.
    files_to_publish << {
      :filename => "index.html",
      :route => "site/#{id}?target_date=#{target_date.strftime('%Y-%m-%d')}&main_index=1",
    }
  end

  rails_admin do
    configure :name, :string
    configure :cta_iframe do
      label "CTA iframe"
    end
    configure :partner_logo_url do
      label "Partner logo URL"
    end
    configure :partner_link_url do
      label "Partner link URL"
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
        field :partner_link_url
      
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
        field :partner_link_url
      
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
      
      group :recent_status do
        field :rate_limit_errors
      end
    end
  end
end
