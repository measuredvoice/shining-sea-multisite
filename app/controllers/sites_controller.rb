class SitesController < ApplicationController
  layout false
  
  def show
    @site = Site.find(params[:id])
    @date = @site.time_zone_obj.today - 1.day
    
    Time.zone = @site.time_zone
    
    @is_main_index = params[:main_index] ? true : false
    
    # Build the ranked list of tweets for this day
    @tweets = @site.ranked_tweets.first(50)
    
  end
  
end
  
