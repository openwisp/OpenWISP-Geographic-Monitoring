class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :http_authenticatable, :token_authenticatable, :recoverable, :confirmable, :lockable, :timeoutable, :registerable and :activatable
  devise :database_authenticatable, :rememberable, :trackable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :username, :email, :password, :password_confirmation
end
