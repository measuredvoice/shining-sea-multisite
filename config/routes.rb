ShiningSeaMultisite::Application.routes.draw do
  devise_for :users

  # Default to the documentation and examples
  root :to => 'documentation#index'


end
