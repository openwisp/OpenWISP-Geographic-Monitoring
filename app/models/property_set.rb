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

  def self.categories(wisp)
    # Categories should be specific for each wisp
    # and dynamic based on which categories are defined
    # on a wisp's access points
    wisp.access_points.map{|ap|
        ap.category
    }.compact.uniq.sort
  end
end
