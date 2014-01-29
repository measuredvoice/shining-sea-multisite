namespace :site do
  desc "Collect a day of metrics for a new site"
  task :collect_first_metrics, [:site_id] => :environment do |t, params|
    start_time = Time.zone.now
    
    site = Site.find(params[:site_id])
    
    puts "Updating the accounts list..."
    site.update_accounts!
    
    puts "Queueing tweet metrics for #{site.name} accounts..."
    
    last_queue_time = Time.zone.now
    site.accounts.each_with_index do |account, queue_position|
      puts "  account: #{account.screen_name}"      

      queue_time = site.queue_time_for(queue_position, :fetch_recent_tweets)
      account.delay(:run_at => queue_time).fetch_recent_tweets!
      puts "    (queued at #{queue_time})"
      last_queue_time = queue_time
    end
    
    end_time = Time.zone.now
    
    elapsed = (end_time - start_time).to_i
    puts "Finished in #{elapsed} seconds. Should finish after #{last_queue_time}."
  end

  desc "Complete metrics for a new site"
  task :complete_first_metrics, [:site_id] => :environment do |t, params|
    start_time = Time.zone.now
    
    site = Site.find(params[:site_id])
        
    puts "Queueing tweets to complete for #{site.name}..."
    
    total_tweets = 0
    last_queue_time = Time.zone.now
    site.tweet_metrics.from_yesterday.each_with_index do |tm, queue_position|
      total_tweets += 1
      puts "   completing metrics for #{tm.tweet_id}..."
      queue_time = site.queue_time_for(queue_position, :complete_metrics)
      tm.delay(:run_at => queue_time).complete_metrics!
      last_queue_time = queue_time
    end
    
    puts "Queued #{total_tweets} tweets."
    end_time = Time.zone.now
    
    elapsed = (end_time - start_time).to_i
    puts "Finished in #{elapsed} seconds. Should finish after #{last_queue_time}."
  end

  desc "Generate a day of HTML for a site"
  task :generate_first_html, [:site_id] => :environment do |t, params|
    start_time = Time.zone.now
    
    site = Site.find(params[:site_id])
    target_date = site.time_zone_obj.now - 1.day

    unless site.ready_to_publish?
      puts "Setting up #{site.name} at #{site.host_url} for the first time..."
      site.prepare_for_publishing!
      
      if site.ready_to_publish?
        puts "...the site is set up!"
      else
        raise "Can't set up the site"
      end
    end
    
    puts "Calculating the rank for all tweets..."
    site.set_tweet_ranks!(target_date)
    
    puts "Writing tweet summary JSON files..."
    site.delay.write_final_metrics_for(target_date)

    puts "Publishing all HTML files..."
    app = ActionDispatch::Integration::Session.new(Rails.application)
    site.html_files_to_publish_for(target_date).each do |file|
      puts "  #{file[:filename]}..."
      app.get(file[:route])
      if app.response.success?
        site.s3_bucket.objects[file[:filename]].write(app.response.body)
        puts "    ...written."
      else
        raise "Can't get HTML from #{file[:route]}. (#{app.response.message})"
      end
    end
    
    puts "Writing asset files..."
    Dir.chdir(Rails.root.join('public'))
    Dir.glob('assets/**/*.*').each do |asset_file|
      puts "  #{asset_file}..."
      site.s3_bucket.objects[asset_file].write(:file => asset_file)
    end

    end_time = Time.zone.now
    
    elapsed = (end_time - start_time).to_i
    puts "Finished in #{elapsed} seconds."
  end
end
