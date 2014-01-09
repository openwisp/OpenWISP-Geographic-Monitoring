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

class PropertySet < ActiveRecord::Base
  belongs_to :access_point
  belongs_to :group

  validates :access_point_id, :presence => true
  validates :category, :format => {
      :with => /^\w+\s|\.|\-*\w+$/,
      :allow_blank => true
  }
  
  validates :manager_email, :email => true, :allow_blank => true
  
  validates :alerts_threshold_down,
            :numericality => { :only_integer => true, :greater_than_or_equal_to => 0 },
            :allow_blank => true
  
  validates :alerts_threshold_up,
            :numericality => { :only_integer => true, :greater_than_or_equal_to => 0 },
            :allow_blank => true

  def self.categories(wisp)
    # Categories should be specific for each wisp
    # and dynamic based on which categories are defined
    # on a wisp's access points
    #wisp.access_points.map{|ap|
    #    ap.category
    #}.compact.uniq.sort
    
    # the old method was refactored because it translated in too many queries on each page view
    # 308 queries on the test database of Provincia Wi-fi (Province of Rome wifi service)
    # this line does just 1 query instead
    access_points = AccessPoint.select('property_sets.category AS c').joins("LEFT JOIN `property_sets` ON `property_sets`.`access_point_id` = `access_points`.`id`").where(:wisp_id => wisp.id).group('c')
    # returns a list of categories
    access_points.map{ |ap| ap.c }
  end

  # DB query
  # finds PropertySets that have no correspondent access_point anymore
  def self.find_orphans
    PropertySet.select('property_sets.id, property_sets.access_point_id, access_points.id AS ap_table_id').
    joins('LEFT JOIN access_points ON property_sets.access_point_id = access_points.id').
    where('access_points.id IS NULL')
  end
  
  # DB query
  # deletes PropertySets that have no correspondent access_point anymore
  def self.destroy_orphans
    find_orphans.each do |orphan|
      PropertySet.find(orphan.id).destroy()
    end
  end
end
