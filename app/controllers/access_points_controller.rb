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

  skip_before_filter :verify_authenticity_token, :only => [
    :change_group,
    :toggle_public,
    :toggle_favourite,
    :batch_change_property,
    :erase_favourite,
    :edit_ap_alert_settings
  ]

  access_control do
    default :deny

    actions :index,:show, :change_group, :select_group, :toggle_public, :toggle_favourite,
            :batch_select_group, :favourite, :reset_favourites, :last_logins, :edit_ap_alert_settings do
      allow :wisps_viewer
      allow :wisp_access_points_viewer, :of => :wisp, :if => :wisp_loaded?
    end

    actions :batch_change_property do
      allow :wisps_viewer
      allow :wisp_access_points_viewer
    end
  end

  def index
    @showmap = CONFIG['showmap']
    @access_point_pagination = CONFIG['access_point_pagination']

    @favourite = params[:filter] == 'favourite' ? true : false

    # if group view
    if params[:group_id]
      begin
        @group = Group.select([:id, :wisp_id, :name, :monitor, :count_stats, :up, :down, :unknown, :total]).where(['wisp_id IS NULL or wisp_id = ?', @wisp.id]).find(params[:group_id])
      rescue ActiveRecord::RecordNotFound
        render :file => "#{Rails.root}/public/404.html", :status => 404, :layout => false
        return
      end
    end

    respond_to do |format|
      format.any(:html, :js) { @access_points = access_points_with_sort_search_and_paginate.of_wisp(@wisp) }
      format.json {
		@access_points = access_points_with_filter.of_wisp(@wisp)
		# if not simple view call draw_map model method which does clusters
		if params[:simple].nil?
		  @access_points = @access_points.draw_map
		end
	  }
      format.rss { @access_points = AccessPoint.of_wisp(@wisp).on_georss }
    end

    crumb_for_group
    crumb_for_wisp
    crumb_for_access_point_favourite
  end

  def show
    @access_point = AccessPoint.with_properties_and_group.find(params[:id])
    @access_point.build_property_set_if_group_name_empty()

    ap_wisp = @access_point.wisp
    unless [ap_wisp.slug, ap_wisp.name, ap_wisp.id, ap_wisp.id.to_s].include?(params[:wisp_id])
	  render :file => "#{Rails.root}/public/404.html", :status => 404, :layout => false
      return
	end

    @from = Date.strptime(params[:from], I18n.t('date.formats.default')) rescue 1.months.ago.to_date
    @to = Date.strptime(params[:to], I18n.t('date.formats.default')) rescue Date.today

    require "net/http"
	require "uri"
    crumb_for_wisp
    crumb_for_access_point
  end

  # retrieve latest logins and sessions that have been started from an AP
  def last_logins
    @access_point = AccessPoint.find(params[:id])
    # retrieve radius accountings
    RadiusSession.active_resource_from(@wisp.owums_url, @wisp.owums_username, @wisp.owums_password)
	@radius_sessions = RadiusSession.find(:all, :params => { :ap => @access_point.common_name, :last => 10 })
	render :layout => false
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

  # toggle published AP in the GeoRSS xml
  def toggle_public
    ap = PropertySet.find_by_access_point_id(params[:id])
    ap.public = !ap.public?
    ap.save!
    respond_to do |format|
      format.json{
        image = view_context.image_path(ap.public ? 'accept.png' : 'delete.png')
        render :json => { 'public' => ap.public, 'image' => image }
      }
    end
  end

  # toggle favourite property
  def toggle_favourite
    ap = PropertySet.find_by_access_point_id(params[:id])
    ap.favourite = !ap.favourite?
    ap.save!
    respond_to do |format|
      format.json{
        image = view_context.image_path(ap.favourite ? 'star.png' : 'star-off.png')
        render :json => { 'favourite' => ap.favourite, 'image' => image }
      }
    end
  end

  def reset_favourites
    @access_points = AccessPoint.with_properties.where(:wisp_id => @wisp.id)

    @access_points.each do |ap|
      if ap.favourite?
        ap.property_set.update_attributes(:favourite => '0' )
      end
    end

    respond_to do |format|
      format.html { redirect_to wisp_access_points_favourite_path(@wisp) }
    end
  end

  def batch_select_group
    if wisp_loaded?
      @groups = Group.all_join_wisp("wisp_id = ? OR wisp_id IS NULL", [@wisp.id])
    else
      # maybe is too much! - for the moment it works so let's keep it
      if current_user.has_role?(:wisps_viewer)
        @groups = Group.all_join_wisp()
      else
        @groups = Group.all_accessible_to(current_user)
      end
    end
    render :template => 'access_points/select_group', :layout => false
  end

  def batch_change_property
    # parameters expected:
    # * access_points (array of IDs)
    # * property_name (string)
    # * property_value (string)
    access_points_ids = params[:access_points]
    property_name = params[:property_name]
    property_value = params[:property_value]

    # ensure all parameters are sent correctly otherwise return 400 bad request status code
    if property_name.nil? or property_name == '' or property_value.nil? or property_value == '' or access_points_ids.nil? or access_points_ids.length < 1
      render :status => 400, :json => { "details" => I18n.t(:Bad_format_parameters) }
      return
    end

    # get an array of id for which the user is authorized
    authorized_for_wisps = current_user.roles_search(:wisp_access_points_viewer).map { |r| r.authorizable_id }

    # in case user the array is empty, the user is wisps_viewer, because even if he is not wisp_access_points_viewer for any wisp
    # he was able to get here (otherwise he would have been blocked before because the acl rules on top)
    wisps_viewer = authorized_for_wisps.length < 1 ? true : false

    access_points = AccessPoint.with_properties.find(access_points_ids)

    case property_name
    when 'group_id'
      # ensure Group is correct otherwise return 404
      begin
        # ensure group is a general group of specific of this wisp
        group = Group.select([:id, :name, :wisp_id]).find(property_value)

        # if moving access points to a group of a specific wisp, user must be authorized for that wisp
        if not group.wisp_id.nil? and not wisps_viewer and not authorized_for_wisps.include?(group.wisp_id)
          render :status => 403, :json => { "details" => I18n.t(:User_does_not_have_permission) }
          return
        end
      rescue ActiveRecord::RecordNotFound
        render :status => 404, :json => { "details" => I18n.t(:Group_not_found) }
        return
      end
    when 'public'
    when 'favourite'
    # otherwise if supplying an unrecognized parameter for "property_name"
    else
      render :status => 400, :json => { "details" => I18n.t(:Unrecognized_property_name) }
      return
    end

    # perform checks first
    access_points.each do |ap|
      # user must be authorized for wisp_id of the access point he wants to edit
      if not wisps_viewer and not authorized_for_wisps.include?(ap.wisp_id)
        render :status => 403, :json => { "details" => I18n.t(:User_does_not_have_permission_ap_id, :ap_id => ap.id) }
        return
      end

      # wisp_id of access point must coincide with wisp_id of group (unless wisp_id of group is NULL)
      if property_name == 'group_id' and not group.wisp_id.nil? and not ap.wisp_id == group.wisp_id
        render :status => 403, :json => { "details" => I18n.t(:Moving_access_point_different_wisp_not_allowed, :wisp1 => ap.wisp.name, :wisp2 => group.wisp.name) }
        return
      end

      # ensure ap has property_sets related object
      if ap.attributes[property_name].nil?
        # create properties!
        ap.properties.save!
      end
    end

    AccessPoint.batch_change_property(access_points, property_name, property_value)

    if property_name == 'group_id' or property_name == 'favourite'
      # update group counts
      Group.update_all_counts()
    end

    render :status => 200, :json => { "details" => I18n.t(:Access_point_updated, :length => access_points.length) }
  end

  def edit_ap_alert_settings
	# get all AP info, needed for comparing
	ap = AccessPoint.with_properties_and_group.find(params[:access_point_id])
	# get properties object, needed for saving eventual changes
	properties = PropertySet.find_by_access_point_id(params[:access_point_id])

	# nothing has been changed yet
	changed = false

	# if manager email supplied
	if params[:manager_email]
	  # change manager email
	  properties.manager_email = params[:manager_email]
	  changed = true
	end

	# if alerts supplied
	if params[:alerts]
	  # change alerts (true or false)
	  properties.alerts = params[:alerts] == 'true' ? true : false;
	  changed = true
	end

	# if alerts_threshold_up supplied
	if params[:alerts_threshold_up]
	  properties.alerts = true if !ap.alerts?
	  # change alerts_threshold_up (integer)
	  properties.alerts_threshold_up = params[:alerts_threshold_up]
	  changed = true
	end

	# if alerts_threshold_down supplied
	if params[:alerts_threshold_down]
	  properties.alerts = true if !ap.alerts?
	  # change alerts_threshold_down (integer)
	  properties.alerts_threshold_down = params[:alerts_threshold_down]
	  changed = true
	end

	if params[:reset]
	  ap.reset_alert_settings()
	  changed = true
	end

	if changed and properties.save
	  render :status => 200, :json => { "details" => "success" }
	elsif changed == false
	  render :status => 200, :json => { "details" => "nothing changed" }
	else
	  render :status => 400, :json => {
		"details" => "validation error",
		"errors" => properties.errors
	  }
	end
  end

  private

  def access_points_with_filter
    access_points = AccessPoint.with_properties_and_group.scoped

    access_points = access_points.filter_favourites(@favourite) if @favourite

    if params[:group_id]
      access_points = access_points.where(:wisp_id => @wisp.id, 'property_sets.group_id' => params[:group_id])
    end

    case params[:filter]
      when 'up'
        access_points.up
      when 'down'
        access_points.down
      when 'unknown'
        access_points.unknown
      else
        access_points
    end
  end

  def access_points_with_sort_search_and_paginate
    query = params[:q] || nil

    # determine ordering
    column = params[:column] ? t_column(params[:column].downcase) : nil
    direction = nil
    if column
      direction = %w{asc desc}.include?(params[:order]) ? params[:order] : 'asc'
    end

    # model delegation caused too many queries, used a workaround in the specific model method
    access_points = AccessPoint.with_properties_and_group.scoped

    # determine group
    if params[:group_id]
      access_points = access_points.where(:wisp_id => @wisp.id, 'property_sets.group_id' => params[:group_id])
    end

    access_points = access_points.filter_favourites(@favourite) if @favourite
    access_points = access_points.quicksearch(query) if query
    # default ordering is ID asc
    access_points = access_points.sort_with(column, direction)


    per_page = params[:per]
    access_points.page(params[:page]).per(per_page)
  end

  def t_column(column)
    i18n_columns = {}
    i18n_columns[I18n.t(:site_description, :scope => [:activerecord, :attributes, :access_point])] = 'site_description'
    i18n_columns[I18n.t(:address, :scope => [:activerecord, :attributes, :access_point])] = 'address'
    i18n_columns[I18n.t(:city, :scope => [:activerecord, :attributes, :access_point])] = 'city'
    i18n_columns[I18n.t(:Mac_address).downcase] = 'mac_address'
    i18n_columns[I18n.t(:Ip_addr).downcase] = 'ip_address'
    i18n_columns[I18n.t(:Activation_date).downcase] = 'activation_date'
    i18n_columns[I18n.t(:Group).downcase] = 'group_name'
    i18n_columns[I18n.t(:favourite, :scope => [:activerecord, :attributes, :access_point])] = 'favourite'
    i18n_columns[I18n.t(:public, :scope => [:activerecord, :attributes, :access_point])] = 'public'
    i18n_columns[I18n.t(:status, :scope => [:activerecord, :attributes, :access_point])] = 'status'


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

  def crumb_for_access_point_favourite
    if @favourite
      add_breadcrumb I18n.t(:Favourite_acccess_points), wisp_access_points_favourite_path(@wisp)
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
