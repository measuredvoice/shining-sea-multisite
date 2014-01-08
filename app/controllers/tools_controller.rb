class ToolsController < ApplicationController
  before_filter :authenticate_user!
  respond_to :html, :csv
  
  def index
    @original_list_source = flash[:list_source]
  end
  
  def twitter_list
    filename = "twitter-list.csv"
    
    if /twitter.com\/(?<username>[\w-]+)\/lists\/(?<list_slug>[\w-]+)/ =~ params[:list_source] 
      # Find the members of the specified list
      twitter = Site.authorized.first.twitter_client
      
      begin
        accounts = twitter.list_members(username, list_slug).to_a
      rescue Twitter::Error::NotFound => e
        flash.alert = "Can't find that list. Check the Twitter list URL."
        flash[:list_source] = params[:list_source]
        redirect_to tools_path
        return
      rescue Twitter::Error => e
        flash.alert = "Something went wrong on Twitter. (#{e}.) Try again later."
        flash[:list_source] = params[:list_source]
        redirect_to tools_path
        return        
      end
      
      filename = "twitter-list-#{username}-#{list_slug}.csv"
    elsif /^#(?<hashtag>[\w]+)/ =~ params[:list_source]
      # Find accounts that tweeted the specified hashtag
      twitter = Site.authorized.first.twitter_client

      begin
        tweets = twitter.search("##{hashtag}", :result_type => "mixed")
        accounts = tweets.collect {|t| t.user}.uniq {|u| u.username}
      rescue Twitter::Error => e
        flash.alert = "Something went wrong on Twitter. (#{e}.) Try again later."
        flash[:list_source] = params[:list_source]
        redirect_to tools_path
        return        
      end
      filename = "twitter-list-hashtag-#{hashtag}.csv"
    else
      # The query needs to be one or the other
      flash.alert = "Make sure you enter a hashtag or correct list URL."
      flash[:list_source] = params[:list_source]
      redirect_to tools_path
      return
    end

    accounts.sort! {|a,b| a.username.downcase <=> b.username.downcase}
    
    respond_to do |format|
      format.html do
      end
      format.csv do
        csv_data = CSV.generate do |csv|
          accounts.each do |account|
            csv << [
              account.username,
              account.name,
            ]
          end
        end

        send_data csv_data,
          :type => 'text/csv; charset=utf-8',
          :disposition => "attachment; filename=#{filename}"
      end
    end
  end
end
