class WispsController < ApplicationController
  before_filter :authenticate_user!

  access_control :helper => :user_can_view_wisp? do
    default :deny

    action :index do
      allow :wisps_viewer
      allow :wisp_hotspots_viewer, :of => :wisp
    end
  end

  def index
    @wisps = Wisp.all
  end
end
