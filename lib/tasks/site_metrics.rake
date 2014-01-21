namespace :site do
  desc "Update the list of accounts for each site (once daily per site)"
  task :update_accounts => :environment do |t|
    # Update each site in its 10th hour (10am) based on its time zone.
    Site.active.in_hour(10).each do |site|
      # puts "Updating accounts for #{site.name}..."
      site.delay.update_accounts!
    end
  end
  
  desc "Clean out old tweet metrics and reset rate errors (once daily per site)"
  task :clean_old_data => :environment do |t|
    # Update each site in its 16th hour (4pm) based on its time zone.
    Site.active.in_hour(16).each do |site|
      # puts "Updating accounts for #{site.name}..."
      site.delay.clear_old_tweet_metrics!
      site.reset_rate_limit_errors!
    end
  end
  
  desc "Update the list of recent tweets for each site (once every 6 hours)"
  task :fetch_recent_tweets => :environment do |t|
    Site.active.each do |site|
      # puts "Checking accounts for #{site.name}..."
      
      max = site.rate_per_hour_for(:fetch_recent_tweets)
      site.accounts.need_new_tweets.limit(max).each_with_index do |account, queue_position|
        # puts "  account: #{account.screen_name}"      

        queue_time = site.queue_time_for(queue_position, :fetch_recent_tweets)
        account.delay(:run_at => queue_time).fetch_recent_tweets!
        # puts "    (queued at #{queue_time})"
      end
    end
  end
  
  desc "Finalize metrics for all tweets (after 6 hours)"
  task :complete_tweet_metrics => :environment do |t|
    Site.active.each do |site|
      puts "Checking tweets for #{site.name}..."
      
      max = site.rate_per_hour_for(:complete_metrics)
      site.tweet_metrics.ready_to_complete.limit(max).each_with_index do |tm, queue_position|
        puts "   completing metrics for #{tm.tweet_id}..."
        
        queue_time = site.queue_time_for(queue_position, :complete_metrics)
        tm.delay(:run_at => queue_time).complete_metrics!
        puts "    (queued at #{queue_time})"
      end
    end
  end
  
end
