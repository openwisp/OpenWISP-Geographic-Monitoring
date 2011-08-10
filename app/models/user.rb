class User < ActiveRecord::Base
  acts_as_authorization_subject

  # Include default devise modules. Others available are:
  # :http_authenticatable, :token_authenticatable, :recoverable,
  # :confirmable, :lockable, :timeoutable, :registerable and :activatable
  devise :database_authenticatable, :rememberable, :trackable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :username, :email, :password, :password_confirmation

  ROLES = [
    :wisps_viewer, :wisp_access_points_viewer,
    :wisp_activities_viewer, :wisp_activity_histories_viewer,
    :wisp_associated_user_counts_viewer, :wisp_associated_user_count_histories_viewer
  ]

  def roles
    @rs = []
    ROLES.each do |r|
      @rs << r if self.has_role?(r)
    end
    @rs
  end

  def roles=(new_roles)
    to_remove = self.roles - new_roles
    to_remove.each do |role|
      self.has_no_role!(role, self.wisp) if self.wisp
      self.has_no_role!(role)
    end

    new_roles.map!{|role| role.to_sym}
    new_roles.each do |role|
      if ROLES.include? role
        self.wisp ? self.has_role!(role, self.wisp) : self.has_role!(role)
      end
    end
  end
end
