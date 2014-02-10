ShiningSeaMultisite::Application.routes.draw do
  devise_for :users
  
  mount RailsAdmin::Engine => '/admin', :as => 'rails_admin'

  # Default to the documentation and examples
  root :to => 'documentation#index'

  # Quick tools section
  match "tools" => "tools#index", :via => :get, :as => :tools
  match "tools/twitter" => "tools#twitter_list", :via => :post, :as => :twitter_list
  
  get "site/:id" => "sites#show"
  get "site/:id/:screen_name/status/:tweet_id" => "tweets#show"

  get "iframes/:id" => "sites#iframe"

  get "site/:id/not_found" => "sites#not_found"
end
