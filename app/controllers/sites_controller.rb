class SitesController < ApplicationController
  layout false
  
  def show
    @site = Site.find(params[:id])
    Time.zone = @site.time_zone
    
    if params[:target_date]
      @date = Time.zone.parse(params[:target_date]).to_date
    else
      @date = @site.time_zone_obj.now - 1.day
    end
    
    @is_main_index = params[:main_index] ? true : false
    
    # Build the ranked list of tweets for this day
    @tweets = @site.ranked_tweets_for(@date).first(50)
    
  end
  
  def iframe
    @site = Site.find(params[:id])    
  end
end
  
