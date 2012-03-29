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

class MacVendor < ActiveRecord::Base
  def self.unknown?(mac_address)
    find_by_mac_address(mac_address).nil?
  end

  def self.get_oui(mac_address)
    if mac_address.scan(/:/).count == 5
      mac_address[0..7]
    else
      mac_address
    end
  end

  def self.find_by_mac_address(mac_address)
    find_by_oui get_oui(mac_address)
  end
end
