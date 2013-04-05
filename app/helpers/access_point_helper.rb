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

module AccessPointHelper
  def categories_select_data(wisp, access_point)    
    data = PropertySet.categories(wisp)
    data.compact! # remove nil
    data.delete("") # remove ""
    # prepare list for javascript
    data = data.map do |category|
      "'#{escape_javascript(category)}':'#{escape_javascript(category)}'" unless category.blank?
    end
    data << "'': '#{t :None}'"
    data << "'!new!': '#{t :Create_new_category}'"
    # return javascript object with list of categories
    "{#{data.join(',')}}"
  end

  def image_path_for(marker)
    image = ''

    if marker.is_a? AccessPoint
      image = 'ap_'
    elsif marker.is_a? Cluster
      image = 'cluster_'
    end

    if marker.up?
      image += 'up.png'
    elsif marker.down?
      image += 'down.png'
    elsif marker.unknown?
      image += 'unknown.png'
    end

    image_path(image)
  end

  def image_tag_for(marker, opts={})
    image_tag image_path_for(marker), opts
  end
end
