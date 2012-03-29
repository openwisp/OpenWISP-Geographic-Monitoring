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

class AssociatedUserCountHistory < ActiveRecord::Base
  belongs_to :access_point

  default_scope order(:start_time)

  def as_json(options={})
    # Time should be in unix epoch time in
    # milliseconds...
    [ start_time.to_i * 1000, count ]
  end

  def self.older_than(time)
    where(:start_time => time.to_time..6.hours.ago)
  end

  def self.observe(from, to)
    where(:last_time => from..to)
  end
end
