# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

  before_filter :set_locale

  private

  def add_breadcrumb(crumb)
    crumbs = session[:breadcrumbs] ||= []

    if crumbs.include?(crumb)
      session[:breadcrumbs] = crumbs[0..crumbs.find_index(crumb)]
    else
      session[:breadcrumbs] << crumb
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
    @wisp = Wisp.find(params[:wisp_id] || params[:id])
    Hotspot.scope_with_wisp @wisp
  end

  # Override Devise to always redirect to
  # root_path after sign_in (even if a referral
  # is provided)
  def stored_location_for(user)
    nil
  end
end
