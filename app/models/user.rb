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

  ROLES = [
    :wisps_viewer, # higher role
    :wisp_access_points_viewer, :wisp_activities_viewer, :wisp_activity_histories_viewer,
    :wisp_associated_user_counts_viewer, :wisp_associated_user_count_histories_viewer,
  ]
  
  def roles
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

  def roles=(new_roles)
    to_remove = self.roles - new_roles
    to_remove.each do |role|     
      remove_role(role)
    end
    
    new_roles.each do |role|
      assign_role(role.name, role.authorizable_id)
    end
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
end
