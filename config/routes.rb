ShiningSeaMultisite::Application.routes.draw do
  devise_for :users
  
  mount RailsAdmin::Engine => '/admin', :as => 'rails_admin'

  # Default to the documentation and examples
  root :to => 'documentation#index'


end
