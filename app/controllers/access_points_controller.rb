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

class AccessPointsController < ApplicationController
  before_filter :authenticate_user!, :load_wisp

  access_control do
    default :deny

    actions :index, :show do
      allow :wisps_viewer
      allow :wisp_access_points_viewer, :of => :wisp, :if => :wisp_loaded?
    end
  end

  def index
    respond_to do |format|
      format.any(:html, :js) { @access_points = access_points_with_sort_search_and_paginate.of_wisp(@wisp) }
      format.json { @access_points = access_points_with_filter.of_wisp(@wisp).draw_map }
      format.rss { @access_points = AccessPoint.of_wisp(@wisp).on_georss }
    end

    crumb_for_wisp
  end

  def show
    @access_point = AccessPoint.find params[:id]

    crumb_for_wisp
    crumb_for_access_point
  end

  private

  def access_points_with_filter
    case params[:filter]
      when 'up'
        AccessPoint.up
      when 'down'
        AccessPoint.down
      when 'unknown'
        AccessPoint.unknown
      else
        AccessPoint
    end
  end

  def access_points_with_sort_search_and_paginate
    query = params[:q] || nil
    column = params[:column] ? params[:column].downcase : nil
    direction = %w{asc desc}.include?(params[:order]) ? params[:order] : 'asc'

    access_points = AccessPoint.scoped
    access_points = access_points.sort_with(t_column(column), direction) if column
    access_points = access_points.quicksearch(query) if query

    access_points.page params[:page]
  end

  def t_column(column)
    i18n_columns = {}
    i18n_columns[I18n.t(:status, :scope => [:activerecord, :attributes, :access_point])] = 'status'
    i18n_columns[I18n.t(:public, :scope => [:activerecord, :attributes, :access_point])] = 'public'
    i18n_columns[I18n.t(:site_description, :scope => [:activerecord, :attributes, :access_point])] = 'site_description'

    AccessPoint.column_names.each do |col|
      i18n_columns[I18n.t(col, :scope => [:activerecord, :attributes, :access_point])] = col
    end

    i18n_columns.include?(column) ? i18n_columns[column] : 'hostname'
  end
  
  def crumb_for_wisp
    begin
      add_breadcrumb I18n.t(:Access_points_for, :wisp => @wisp.name), wisp_access_points_path(@wisp)
    rescue
      add_breadcrumb I18n.t(:Access_points_of_every_wisp), access_points_path
    end
  end

  def crumb_for_access_point
    add_breadcrumb I18n.t(:Access_point_named, :hostname => @access_point.hostname), wisp_access_point_path(@access_point.wisp, @access_point)
  end
end
