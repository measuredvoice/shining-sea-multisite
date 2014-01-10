# RailsAdmin config file. Generated on December 09, 2013 15:26
# See github.com/sferik/rails_admin for more informations

RailsAdmin.config do |config|


  ################  Global configuration  ################

  # Set the admin name here (optional second array element will appear in red). For example:
  config.main_app_name = ['Shining Sea Multisite', 'Admin']
  # or for a more dynamic name:
  # config.main_app_name = Proc.new { |controller| [Rails.application.engine_name.titleize, controller.params['action'].titleize] }

  # RailsAdmin may need a way to know who the current user is]
  config.current_user_method { current_user } # auto-generated

  # If you want to track changes on your models:
  # config.audit_with :history, 'User'

  # Or with a PaperTrail: (you need to install it first)
  # config.audit_with :paper_trail, 'User'

  # Display empty fields in show views:
  config.compact_show_view = false

  # Number of default rows per-page:
  # config.default_items_per_page = 20

  # Exclude specific models (keep the others):
  # config.excluded_models = ['Site', 'User']

  # Include specific models (exclude the others):
  # config.included_models = ['Site', 'User']

  # Label methods for model instances:
  # config.label_methods << :description # Default is [:name, :title]

  config.actions do
    # root actions
    dashboard                     # mandatory
    # collection actions 
    index                         # mandatory
    new do
      only [User, Site]
    end
    export
    # member actions
    show
    edit do
      only [User, Site]
    end
    delete do
      only User
    end
  end

  ################  Model configuration  ################

  # Model configuration is listed in the rails_admin section of the model file.

end
