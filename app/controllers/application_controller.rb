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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  helper_method :wisp_loaded?
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  add_breadcrumb proc{ I18n.t(:Home) }, :root_path

  before_filter :load_menu_wisps
  before_filter :set_locale
  before_filter :authenticate_user!, :only => :index
  
  # catch Access Denied exception
  rescue_from 'Acl9::AccessDenied', :with => :access_denied
  
  def index
    # if admin of a specific wisp only
    wisp_access_points_viewers = current_user.roles_search(:wisp_access_points_viewer)
    if not current_user.has_role?(:wisps_viewer) and wisp_access_points_viewers.length == 1
      # redirect to group view
      @index_redirect = wisp_groups_path(Wisp.find(wisp_access_points_viewers[0].authorizable_id))
      redirect_to @index_redirect
    else
      @index_redirect = wisps_path
      # redirect to wisp list
      redirect_to @index_redirect
    end
  end
  
  private

  def load_menu_wisps
    if current_user
      cache_key = "/users/#{current_user.id}/wisps_menu"
      @wisps_menu = Rails.cache.fetch(cache_key)
      if @wisps_menu.nil?
        @wisps_menu = Wisp.all_accessible_to(current_user)
        Rails.cache.write(cache_key, @wisps_menu)
      end
    else
      @wisps_menu = []
    end
  end

  def set_locale
    # if params[:locale] is nil then I18n.default_locale will be used
    I18n.locale = params[:locale]
  end

  def default_url_options
    params.has_key?(:locale) ? {:locale => params[:locale]} : {}
  end

  def load_wisp
    wisp_id = params[:wisp_id] || params[:id]
    if wisp_id
      # when wisp_id is a string
      if wisp_id.to_i == 0
        @wisp = Wisp.find_by_name(wisp_id.gsub('-', ' '))
      # when wisp_id is a number
      else
        @wisp = Wisp.find(wisp_id)
      end
    # view all access points case
    elsif request.path.include?('/access_points')
      @wisp = nil
    # 404
    else
      raise ActionController::RoutingError.new(I18n.t('errors.messages.not_found'))
    end
  end

  def wisp_loaded?
    !@wisp.nil?
  end
  
  def wisp_breadcrumb(force=false)
    if force or wisp_loaded?
      add_breadcrumb(I18n.t(:Wisp_list), wisps_path)
    end
  end
  
  def access_denied
    if current_user
      # It's presumed you have a template with words of pity and regret
      # for unhappy user who is not authorized to do what he wanted
      render :template => 'layouts/access_denied', :status => 403
    else
      # In this case user has not even logged in. Might be OK after login.
      flash[:notice] = 'Access denied. Try to log in first.'
      redirect_to login_path
    end
  end
end
