# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  helper_method :wisp_loaded?
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

  before_filter :set_locale

  private

  def set_locale
    # if params[:locale] is nil then I18n.default_locale will be used
    I18n.locale = params[:locale]
  end

  def default_url_options
    params.has_key?(:locale) ? {:locale => params[:locale]} : {}
  end

  def load_wisp
    @wisp = Wisp.find(params[:wisp_id] || params[:id]) rescue nil
  end

  def wisp_loaded?
    !@wisp.nil?
  end
end
