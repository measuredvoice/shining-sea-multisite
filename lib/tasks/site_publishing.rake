namespace :site do
  desc "Set up new sites on AWS"
  task :set_up_publishing => :environment do
    start_time = Time.zone.now
    
    Site.active.in_hour(6).each do |site|
      target_date = site.time_zone_obj.now - 1.day

      unless site.ready_to_publish?
        puts "Setting up #{site.name} at #{site.host_url} for the first time..."
        site.prepare_for_publishing!
        
        unless site.ready_to_publish?
          site.active = false
          site.save
        end
      end
    end
    
    end_time = Time.zone.now
    
    elapsed = (end_time - start_time).to_i
    puts "Finished in #{elapsed} seconds."
  end
  
  desc "Publish a day of JSON and HTML for each site (once per day)"
  task :publish_site_files => :environment do
    start_time = Time.zone.now
    
    Site.active.in_hour(9).each do |site|
      target_date = site.time_zone_obj.now - 1.day

      next unless site.ready_to_publish?
    
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
    end

    end_time = Time.zone.now
    
    elapsed = (end_time - start_time).to_i
    puts "Finished in #{elapsed} seconds."
  end

  desc "Schedule retweets and congratulatory tweets"
  task :send_congrats_tweets => :environment do
    start_time = Time.zone.now
    
    Site.active.in_hour(11).each do |site|
      target_date = site.time_zone_obj.now - 1.day
      
      site.send_congrats_for(target_date)
    end
    
    end_time = Time.zone.now
    
    elapsed = (end_time - start_time).to_i
    puts "Finished in #{elapsed} seconds."
  end
  
end
