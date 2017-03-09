# This file is part of the OpenWISP Geographic Monitoring
#
# Copyright (C) 2012 OpenWISP.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

class User < ActiveRecord::Base
  acts_as_authorization_subject

  # Include default devise modules. Others available are:
  # :http_authenticatable, :token_authenticatable, :recoverable,
  # :confirmable, :lockable, :timeoutable, :registerable and :activatable
  devise :database_authenticatable, :rememberable, :trackable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :username, :email, :password, :password_confirmation
  
  validates_uniqueness_of :email
  validates_presence_of :username, :email
  validates :password, :confirmation => true
  validate :password_confirmation_cannot_be_empty
  
  after_save :invalidate_cache
  after_destroy :invalidate_cache
  
  attr_accessible :password_confirmation

  ROLES = [
    :wisps_viewer, # higher role
    :wisp_username_viewer,
    :wisp_access_points_viewer, :wisp_activities_viewer, :wisp_activity_histories_viewer,
    :wisp_associated_user_counts_viewer, :wisp_associated_user_count_histories_viewer,
  ]
  
  def roles(force_query=false)
    # don't query the database multiple times if it is not necessary unless explicitly specified
    if not force_query and @roles
      return @roles
    end
    if self.id
      @roles = Role.find_by_sql("SELECT * FROM roles LEFT JOIN roles_users ON roles.id = roles_users.role_id WHERE roles_users.user_id = #{self.id}")
    else
      @roles = Role.all
    end
  end
  
  def roles_id
    roles = self.roles()
    list = []
    unless self.id.nil?
      roles.each do |role|
        list << role.id
      end
    end
    list
  end
  
  # retrieve roles from the database and loop over them to find a specific one
  # makes it possible to do several searchs during an iteration with only 1 DB query
  def roles_include?(name, object_id=nil)
    name = name.to_s
    # get roles from DB if not already available
    @roles = @roles || self.roles()
    # loop over each role and if the role we are looking for is there return true
    @roles.each do |role|
      if role.name == name and (object_id.nil? or role.authorizable_id == object_id)
        return true
      end
    end
    # if nothing found
    return false
  end
  
  def roles_search(role_name)
    # return a list of roles that have the same name (but possibly different authorizable_id)
    if self.id
      Role.find_by_sql(["SELECT * FROM roles LEFT JOIN roles_users ON roles.id = roles_users.role_id WHERE roles_users.user_id = ? AND name = ?", self.id, role_name])
    else
      []
    end
  end

  def roles=(new_roles)
    to_remove = self.roles - new_roles
    to_remove.each do |role|     
      remove_role(role)
    end
    
    new_roles.each do |role|
      assign_role(role.name, role.authorizable_id)
    end
    
    @roles = self.roles(force=true)
  end
  
  def assign_role(name, wisp_id=nil)
    unless wisp_id.nil?
      self.has_role!(name, Wisp.find(wisp_id))
    else
      self.has_role!(name)
    end    
  end
  
  def remove_role(role)
    ActiveRecord::Base.connection.execute("DELETE FROM roles_users WHERE roles_users.user_id = #{self.id.to_i} AND roles_users.role_id = #{role.id}")
  end
  
  def display_roles(separator=', ')
    roles = self.roles()
    @output = ''
    roles.each_with_index do |role, i|
      @output += i < 1 ? '%s' % role : '%s %s' % [separator, role]
    end
    @output
  end
  
  def self.available_roles
    ROLES
  end
  
  def password_confirmation_cannot_be_empty
    # allow changes on existing records without submitting a new password
    if not new_record? and !password.blank? and password_confirmation.blank?
      errors.add(:password_confirmation, I18n.t('activerecord.errors.models.user.attributes.password_confirmation.blank'))
    # require password on new records
    elsif new_record? and (password.blank? or password_confirmation.blank?)
      errors.add(:password_confirmation, I18n.t('activerecord.errors.models.user.attributes.password.blank'))
    end
  end
  
  private
  
  def invalidate_cache
    Rails.cache.delete("/users/#{self.id}/wisps_menu")
  end
end
