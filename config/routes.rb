ShiningSeaMultisite::Application.routes.draw do
  devise_for :users
  
  mount RailsAdmin::Engine => '/admin', :as => 'rails_admin'

  # Default to the documentation and examples
  root :to => 'documentation#index'

  # Quick tools section
  match "tools" => "tools#index", :via => :get, :as => :tools
  match "tools/twitter" => "tools#twitter_list", :via => :post, :as => :twitter_list

end
