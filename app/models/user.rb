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
      #self.has_no_role!(role, self.wisp) if self.wisp
      self.has_no_role!(role)
    end

    new_roles.map!{|role| role.to_sym}
    new_roles.each do |role|
      if ROLES.include? role
        #self.wisp ? self.has_role!(role, self.wisp) : self.has_role!(role)
        self.has_role!(role)
      end
    end
  end
  
  def display_roles(separator=', ')
    roles = self.roles()
    @output = ''
    roles.each_with_index do |role, i|
      @output += i < 1 ? '%s' % role : '%s %s' % [separator, role]
    end
    @output
  end
end
