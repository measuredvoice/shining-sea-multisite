class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :recoverable, :registerable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :rememberable, :trackable, :validatable

  attr_accessible :email, :password, :password_confirmation, :remember_me
  # attr_accessible :title, :body
  
  rails_admin do
    list do
      field :email
      field :current_sign_in_at
      field :last_sign_in_at
    end
  end
end
