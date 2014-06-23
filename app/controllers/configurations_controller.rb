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

class ConfigurationsController < ApplicationController
	before_filter :authenticate_user!

	access_control do
    default :deny
    allow :wisps_viewer
  end
	
	def edit
		to_configure = params[:id]

		case to_configure
		when 'owmw'
			@configurations = Configuration.owmw
		end
		
		add_breadcrumb(I18n.t(:Configure_owmw), edit_configuration_path('owmw'))
	end

	def update
		configurations = params[:configurations]

		configurations.each do |key, content|
			case content[:format]
			when 'boolean'
				Configuration.set(key, content[:value], 'boolean')
			when 'array'
				Configuration.set(key, content[:value], 'array')
			end
		end

		redirect_to root_path
	end
end