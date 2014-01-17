class TweetsController < ApplicationController
  
  def show
    @site = Site.find(params[:id])
    @account = @site.accounts.find_by_screen_name(params[:screen_name])
    @tweet_metric = @account.tweet_metrics.find_by_tweet_id(params[:tweet_id])
  end
  
end
  
