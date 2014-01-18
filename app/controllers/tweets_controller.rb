class TweetsController < ApplicationController
  layout false
  
  def show
    @site = Site.find(params[:id])
    @account = @site.accounts.find_by_screen_name(params[:screen_name])
    @tweet = @account.tweet_metrics.find_by_tweet_id(params[:tweet_id])
    
    @date = @tweet.published_at.in_time_zone(@site.time_zone).to_date
    
    @daily_prev = @tweet.previous_by_rank
    @daily_next = @tweet.next_by_rank
  end
end
  
