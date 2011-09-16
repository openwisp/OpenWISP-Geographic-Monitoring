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

class AssociatedUserCountHistoriesController < ApplicationController
  before_filter :authenticate_user!, :load_wisp

  access_control do
    default :deny

    actions :show do
      allow :wisps_viewer
      allow :wisp_associated_user_count_histories_viewer, :of => :wisp, :if => :wisp_loaded?
    end
  end

  def show
    @associated_user_count_history = AssociatedUserCountHistory.where(:access_point_id => params[:access_point_id]).older_than(31.days.ago)

    respond_to do |format|
      format.json { render :json => @associated_user_count_history }
    end
  end
end
