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

  add_breadcrumb proc{ I18n.t(:Wisp_list) }, :root_path

  before_filter :set_locale
  
  # catch Access Denied exception
  rescue_from 'Acl9::AccessDenied', :with => :access_denied

  private

  def set_locale
    # if params[:locale] is nil then I18n.default_locale will be used
    I18n.locale = params[:locale]
  end

  def default_url_options
    params.has_key?(:locale) ? {:locale => params[:locale]} : {}
  end

  def load_wisp
    @wisp = Wisp.find_by_name(params[:wisp_id] || params[:id]) rescue nil
  end

  def wisp_loaded?
    !@wisp.nil?
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
