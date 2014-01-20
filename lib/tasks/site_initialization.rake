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

  desc "Generate a day of HTML for a new site"
  task :generate_first_html, [:site_id] => :environment do |t, params|
    start_time = Time.zone.now
    
    site = Site.find(params[:site_id])
    puts "Generating HTML for #{site.name}..."
    
    puts "Calculating the rank for all tweets..."
    site.set_tweet_ranks!
    
    puts "Writing tweet summary JSON files..."
    site.ranked_tweets.each do |tweet|
      summary = tweet.as_summary
      site.write_summary_to_s3(summary)
    end

    # TODO: Create a list of routes and filenames to publish,
    #   and loop through them all at once rather than individually.
    
    # First, write files for the individual tweets.
    app = ActionDispatch::Integration::Session.new(Rails.application)
    puts "Writing tweet detail pages..."
    total_tweets = 0
    site.ranked_tweets.each do |tweet|
      filename = "#{tweet.account.screen_name}/status/#{tweet.tweet_id}/index.html"
      
      puts "  #{filename}..."
      route = "site/#{site.id}/#{tweet.account.screen_name}/status/#{tweet.tweet_id}"
      app.get(route)
      if app.response.success?
        site.s3_bucket.objects[filename].write(app.response.body)
        puts "    ...written."
      else
        raise "Can't get tweet details from #{route}. (#{app.response.message})"
      end
      
      total_tweets += 1
    end
    
    # Next, write the dated version of the index file.
    puts "Writing daily ranking file..."
    yesterday = site.time_zone_obj.now - 1.day
    daily_file = "top/#{yesterday.strftime('%Y-%m-%d')}/index.html"
    puts "  #{daily_file}..."
    daily_route = "site/#{site.id}"
    app.get(daily_route)
    if app.response.success?
      site.s3_bucket.objects[daily_file].write(app.response.body)
      puts "    ...written."
    else
      raise "Can't get daily ranking from #{daily_route}. (#{app.response.message})"
    end
    
    # Next, write the updated iframe file.
    puts "Writing iframe file..."
    iframe_file = "iframes/#{site.id}/index.html"
    puts "  #{iframe_file}..."
    iframe_route = "iframes/#{site.id}"
    app.get(iframe_route)
    if app.response.success?
      site.s3_bucket.objects[iframe_file].write(app.response.body)
      puts "    ...written."
    else
      raise "Can't get daily iframe from #{iframe_route}. (#{app.response.message})"
    end
    
    # Next, copy the supporting asset files.
    puts "Writing asset files..."
    Dir.chdir(Rails.root.join('public'))
    Dir.glob('assets/**/*.*').each do |asset_file|
      puts "  #{asset_file}..."
      site.s3_bucket.objects[asset_file].write(:file => asset_file)
    end
    
    # Finally, write the main index file.
    puts "Writing index file..."
    index_file = "index.html"
    puts "  #{index_file}..."
    index_route = "site/#{site.id}?main_index=1"
    app.get(index_route)
    if app.response.success?
      site.s3_bucket.objects[index_file].write(app.response.body)
      puts "    ...written."
    else
      raise "Can't get main index from #{index_route}. (#{app.response.message})"
    end

    puts "Generated HTML for #{total_tweets} tweets."
    end_time = Time.zone.now
    
    elapsed = (end_time - start_time).to_i
    puts "Finished in #{elapsed} seconds."
  end
end
