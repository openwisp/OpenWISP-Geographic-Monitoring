# This file is part of the OpenWISP Geographic Monitoring
#
# Copyright (C) 2010 CASPUR (wifi@caspur.it)
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

namespace :mac_vendors do
  desc "Fetch oui <-> manufacturer association file from http://standards.ieee.org/develop/regauth/oui/oui.txt"
  task :update => :environment do
    require 'open-uri'

    puts "Updating ouis from http://standards.ieee.org/develop/regauth/oui/oui.txt"
    MacVendor.destroy_all
    open('http://standards.ieee.org/develop/regauth/oui/oui.txt').each do |line|
      match = line.match(/([0123456789ABCDEF]{2}-[0123456789ABCDEF]{2}-[0123456789ABCDEF]{2})\s+\(hex\)\s+(.*$)/)

      if match
        oui = match[1].gsub(/-/, ':')
        vendor = match[2]

        MacVendor.create! :vendor => vendor, :oui => oui
      end
    end
  end
end
