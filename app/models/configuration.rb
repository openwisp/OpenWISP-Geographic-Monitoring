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

class Configuration < ActiveRecord::Base

  validates :key, :presence => true,
            :format => { :with => /\A[a-z_\.,]+\Z/ }
  validates :value_format, :presence => true

  def self.get(key)
    value = AppConfig[key]
    raise("BUG: value for key #{key} not found!") if value.nil?
    
    if value.class == Array and value.length == 1 and value[0].include?(',')
      value = value[0].split(',')
    end
    
    value
  end

  def self.set(key, value, format, description=nil)
    key = key.to_s
    value = value.to_s
    format = format.to_s
    
    if format == 'array'
      # if format is array
      # use comma separator without space, convert space between words with dashes
      value = value.gsub(', ', ',').gsub(/ /,"-").downcase
    end

    begin
      AppConfig.set_key(key, value, format)

      configuration = find_or_initialize_by_key(key)

      configuration.update_attributes!(
          :key => key,
          :value => value,
          :value_format => format,
          :description => description
      )
    rescue
      raise("BUG: key #{key} could not be set!")
    end
  end

  def self.owmw
    where("`key` LIKE ?", "%owmw%")
  end

  def is_boolean?
    value_format == 'boolean'
  end

  def is_array?
    value_format == 'array'
  end

  def is_hash?
    value_format == 'hash'
  end
end
