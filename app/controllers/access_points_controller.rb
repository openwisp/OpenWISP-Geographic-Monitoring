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
  before_filter :authenticate_user!, :load_wisp, :wisp_breadcrumb
  
  skip_before_filter :verify_authenticity_token, :only => [:change_group, :toggle_public]

  access_control do
    default :deny

    actions :index, :show, :change_group, :select_group, :toggle_public do
      allow :wisps_viewer
      allow :wisp_access_points_viewer, :of => :wisp, :if => :wisp_loaded?
    end
  end

  def index
    @showmap = CONFIG['showmap']
    @access_point_pagination = CONFIG['access_point_pagination']
    
    # if group view
    if params[:group_id]
      begin
        @group = Group.select([:id, :name, :monitor, :up, :down, :unknown]).where(['wisp_id IS NULL or wisp_id = ?', @wisp.id]).find(params[:group_id])  
      rescue ActiveRecord::RecordNotFound
        render :file => "#{Rails.root}/public/404.html", :status => 404, :layout => false
        return
      end
    end
    
    respond_to do |format|
      format.any(:html, :js) { @access_points = access_points_with_sort_search_and_paginate.of_wisp(@wisp) }
      format.json { @access_points = access_points_with_filter.of_wisp(@wisp).draw_map }
      format.rss { @access_points = AccessPoint.of_wisp(@wisp).on_georss }
    end

    crumb_for_group
    crumb_for_wisp
  end

  def show
    @access_point = AccessPoint.with_properties_and_group.find(params[:id])
    @properties = @access_point.properties

    crumb_for_wisp
    crumb_for_access_point
  end
  
  def select_group
    @access_point_id = params[:access_point_id]
    @groups = Group.all_join_wisp("wisp_id = ? OR wisp_id IS NULL", [@wisp.id])
    render :layout => false
  end
  
  def change_group
    # ensure AP and Group are correct otherwise return 404
    begin
      ap = AccessPoint.find(params[:access_point_id])
      # ensure group is a general group of specific of this wisp
      group = Group.select([:id, :name]).where(['wisp_id IS NULL or wisp_id = ?', @wisp.id]).find(params[:group_id])
    rescue ActiveRecord::RecordNotFound
      render :status => 404, :nothing => true
      return
    end
    # get or create property set
    property_set = ap.properties
    # change gorup, save and return json response
    property_set.group_id = group.id
    property_set.save!
    # update group counts (total, up, down, unknown)
    Group.update_all_counts()
    respond_to do |format|
      format.json { render :json => group.attributes }
    end
  end
  
  def select_group
    @access_point_id = params[:access_point_id]
    @groups = Group.all_join_wisp("wisp_id = ? OR wisp_id IS NULL", [@wisp.id])
    render :layout => false
  end
  
  # toggle published AP in the GeoRSS xml
  def toggle_public
    ap = AccessPoint.find(params[:id])
    ap.public = !ap.public
    ap.save!
    respond_to do |format|
      format.json{
        image = view_context.image_path(ap.public ? 'accept.png' : 'delete.png')
        render :json => { 'public' => ap.public, 'image' => image }
      }
    end
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
    if params[:group_id]
      access_points = AccessPoint.select('access_points.*, property_sets.group_id').with_properties.where(:wisp_id => @wisp.id, 'property_sets.group_id' => params[:group_id])
    end
    access_points = access_points.sort_with(t_column(column), direction) if column
    access_points = access_points.quicksearch(query) if query

    per_page = params[:per]
    access_points.page(params[:page]).per(per_page)
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
      if params[:group_id]
        add_breadcrumb I18n.t(:Access_points_for_group, :group => @group.name), wisp_group_access_points_path(@wisp, @group)
      else
        add_breadcrumb I18n.t(:Access_points_for, :wisp => @wisp.name), wisp_access_points_path(@wisp)
      end
    rescue
      add_breadcrumb I18n.t(:Access_points_of_every_wisp), access_points_path
    end
  end

  def crumb_for_access_point
    add_breadcrumb I18n.t(:Access_point_named, :hostname => @access_point.hostname), wisp_access_point_path(@access_point.wisp, @access_point)
  end
  
  def crumb_for_group
    if params[:group_id]
      add_breadcrumb(I18n.t(:Group_list_of_wisp, :wisp => @wisp.name), wisp_groups_path(@wisp))
    end
  end
end
