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

class AssociatedUserCount < ActiveRecord::Base
  belongs_to :access_point

  default_scope order(:created_at)

  scope :recent, proc{ where("created_at > ?", 6.hours.ago) }
  scope :not_recent, proc{ where("created_at <= ?", 6.hours.ago) }

  def as_json(options={})
    # Time should be in unix epoch time in
    # milliseconds...
    [ created_at.to_i * 1000, count ]
  end
end
