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

class Wisp < ActiveRecord::Base
  acts_as_authorization_object

  has_many :access_points
  has_many :groups, :dependent => :destroy

  delegate :up, :down, :known, :unknown, :favourite, :to => :access_points, :prefix => true

  def to_param
    "#{name.downcase.gsub(/[^a-z0-9]+/i, '-')}"
  end

  def owmw_enabled?
    Configuration.get(:owmw_enabled) && Configuration.get(:wisps_with_owmw).include?(name)
  end
  
  # create unassigned roles for this wisp
  def create_roles
    roles = User.available_roles
    new_roles = []
    roles.each do |role|
      next if role == :wisps_viewer
      unless Role.where({:authorizable_id => self.id, :name => role.to_s}).length > 0
        new_roles << Role.create({:authorizable_type => 'Wisp', :name => role.to_s, :authorizable_id => self.id})
      end      
    end
    new_roles
  end
  
  # the following method takes in consideration the "count_stats" column of the table group
  # only access points with following conditions are counted:
  #   * access points assigned to a group which has "count_stats" == true are counted
  #   * access points with no property set record associated
  def count_access_points(action=:total)
    groups_where = 'groups.count_stats IS NULL OR groups.count_stats = 1'
    
    case action.to_sym
    when :total
      # all indipendently on the value of reachable
      property_sets_where = false
    when :up
      # only reachable ap
      property_sets_where = { :property_sets => { :reachable => true } }
    when :down
      # only unreachable ap
      property_sets_where = { :property_sets => { :reachable => false } }
    when :unknown
      # only unknown .. it means it has no property set yet
      property_sets_where = { :property_sets => { :reachable => nil } }
    else
      raise ArgumentError, 'unknown action argument "%s", can be only "total", "up", "down" or "unknown"' % action
    end
    
    # scope the query so we can add more restrictions to the lookup if needed
    query = AccessPoint.with_properties_and_group('groups.count_stats').of_wisp(self).where(groups_where).scoped
    # in all the cases except total
    if property_sets_where
      query = query.where(property_sets_where)
    end
    
    # return count only
    return query.count()
  end
  
  ### Static methods ###
  
  # creates are roles if missing
  def self.create_all_roles
    self.all.each do |wisp|
      wisp.create_roles
    end
  end
  
  # creates all roles if it finds a number of roles that is less than expected
  # is run automatically when displaying "edit user" and "new user" pages
  def self.create_all_roles_if_necessary
    wisps = Wisp.count
    roles = Role.count
    if roles < wisps * 5 + 1
      self.create_all_roles
    end
  end
  
  def self.collection(user)
    collection = [[I18n.t('No_wisp'), nil]]
    #roles = user.roles 
    is_wisp_viewer = user.roles_include?(:wisps_viewer)
    Wisp.select([:id, :name]).all.each do |wisp|
      collection << [wisp.name, wisp.id] if is_wisp_viewer or user.roles_include?(:wisp_access_points_viewer, wisp.id)
    end
    collection
  end
  
  # select wisps accessible to user
  def self.all_accessible_to(user)
    if user.nil?
      return []
    end
    # if user has role "wisps_viewer" he can see all the groups
    if user.has_role?(:wisps_viewer)
      Wisp.all
    else
      # if user has any role "wisp_access_points_viewer" of some specific wisp return those wisp
      wisp_id_list = user.roles_search(:wisp_access_points_viewer).map{ |role| role.authorizable_id }
      unless wisp_id_list.length <= 0
        Wisp.find(wisp_id_list)
      else
        # if user has neither wisps_viewer nor wisp_access_points_viewer roles return an empty list
        []
      end
    end
  end
end
