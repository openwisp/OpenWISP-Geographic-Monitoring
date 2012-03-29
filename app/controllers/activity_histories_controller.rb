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

class ActivityHistoriesController < ApplicationController
  before_filter :authenticate_user!, :load_wisp

  access_control do
    default :deny

    actions :index, :show do
      allow :wisps_viewer
      allow :wisp_activity_histories_viewer, :of => :wisp, :if => :wisp_loaded?
    end
  end

  def index
    @from = Date.strptime(params[:from], I18n.t('date.formats.default')) rescue 365.days.ago.to_date
    @to = Date.strptime(params[:to], I18n.t('date.formats.default')) rescue Date.today
    @access_points = AccessPoint.activated(@to).of_wisp(@wisp)

    crumb_for_report
  end

  def show
    @activity_history = ActivityHistory.where(:access_point_id => params[:access_point_id]).older_than(30.days.ago)

    respond_to do |format|
      format.json { render :json => @activity_history }
    end
  end

  private

  def crumb_for_report
    add_breadcrumb I18n.t(:Availability_report_for, :wisp => @wisp.name), wisp_availability_report_path(@wisp)
  end
end
