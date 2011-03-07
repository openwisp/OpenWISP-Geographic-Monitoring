class WispsController < ApplicationController
  before_filter :authenticate_user!

  access_control do
    default :deny

    action :index do
      allow :wisps_viewer
      allow :wisp_hotspots_viewer, :of => :wisp
    end
  end

  def index
    @wisps = Wisp.all

    add_breadcrumb :name => I18n.t(:Wisp_list), :path => wisps_path
  end
end
