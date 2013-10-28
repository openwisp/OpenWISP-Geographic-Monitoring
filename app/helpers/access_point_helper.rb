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

    if marker.unknown? or !marker.monitor?
      image += 'unknown.png'
    elsif marker.up?
      image += 'up.png'
    elsif marker.down?
      image += 'down.png'
    end

    image_path(image)
  end

  def image_tag_for(marker, opts={})
    image_tag image_path_for(marker), opts
  end
  
  def select_group_data_href(wisp, access_point_id, group_id)
    unless access_point_id.nil?
      ("data-href=\"%s\"" % [wisp_access_point_change_group_path(wisp, access_point_id, group_id)]).html_safe
    end
  end
  
  def link_to_group(group_name, wisp, group_id)
    if not group_id.nil? and not wisp.nil?
      link_to(group_name, wisp_group_access_points_path(wisp, group_id))
    elsif wisp.nil?
      group_name
    end
  end
  
  def select_group_url_if_wisp_loaded
    if wisp_loaded?
      select_group_wisp_path(@wisp)
    else
      select_group_access_points_path
    end
  end
  
  def show_stat(action, count)
    ("<span class='%s'><b>%s:</b> %s</span>" % [action, t(action), count]).html_safe
  end
end
