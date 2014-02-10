class SitesController < ApplicationController
  layout false
  
  def show
    @site = Site.find(params[:id])
    Time.zone = @site.time_zone
    
    if params[:target_date]
      @date = @site.time_zone_obj.parse(params[:target_date])
    else
      @date = @site.time_zone_obj.now - 1.day
    end
    
    @is_main_index = params[:main_index] ? true : false
    
    # Build the ranked list of tweets for this day
    @tweets = @site.top_ranked_tweets_for(@date)
    
  end
  
  def iframe
    @site = Site.find(params[:id])    
  end

  def not_found
    @site = Site.find(params[:id])    
  end
end
  
