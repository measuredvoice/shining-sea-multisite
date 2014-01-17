namespace :site do
  desc "Collect a day of metrics for a new site"
  task :collect_first_metrics, [:site_id] => :environment do |t, params|
    start_time = Time.zone.now
    
    site = Site.find(params[:site_id])
    
    unless site.ready_to_publish?
      puts "Setting up #{site.name} at #{site.host_url} for the first time..."
      site.prepare_to_publish!
      
      if site.ready_to_publish?
        puts "...the site is set up!"
      else
        raise "Can't set up the site"
      end
    end
    
    puts "Updating the accounts list..."
    site.update_accounts!
    
    puts "Collecting tweets for #{site.name} accounts..."
    
    total_tweets = 0
    total_accounts = 0
    represented_accounts = 0
    time_spent_waiting = 0
    site.accounts.each do |account|
      total_accounts += 1
      puts "  account: #{account.screen_name}"      

      tweets = account.fetch_recent_tweets!
      puts "    (fetched #{tweets.count} tweets)"
      time_spent_waiting += 15
      sleep 15
      
      tweet_metrics = account.tweet_metrics.from_yesterday
      if tweet_metrics.count > 0
        represented_accounts += 1
        puts "   (#{tweet_metrics.count} tweets yesterday)"
        tweet_metrics.each do |tm|
          total_tweets += 1
          puts "   completing metrics for #{tm.tweet_id}..."
          tm.complete_metrics!
          if tm.engagement > 0 
            time_spent_waiting += 15
            sleep 15
          else
            time_spent_waiting += 5
            sleep 5
          end
        end
      else
        puts "   (no tweets from yesterday)"
      end
      puts "  done completing metrics for #{account.screen_name}"
    end
    
    puts "Collected #{total_tweets} tweets for #{represented_accounts} accounts (of #{total_accounts})."
    end_time = Time.zone.now
    
    elapsed = (end_time - start_time).to_i
    puts "Finished in #{elapsed} seconds."
    puts "Spent #{time_spent_waiting} seconds waiting."
  end
end
