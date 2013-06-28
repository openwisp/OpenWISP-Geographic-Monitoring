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

class Role < ActiveRecord::Base
  acts_as_authorization_role
  
  def to_s
    self.name
  end
  
  def self.all_join_wisp
    self.find_by_sql("SELECT roles.*, wisps.name AS wisp_name, wisps.id AS wisp_id
                    FROM roles LEFT JOIN wisps ON wisps.id = roles.authorizable_id
                    ORDER BY wisp_id")
  end
end