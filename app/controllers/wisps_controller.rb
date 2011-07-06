class WispsController < ApplicationController
  before_filter :authenticate_user!

  access_control do
    default :deny

    action :index do
      allow :wisps_viewer
      allow :wisp_access_points_viewer, :of => :wisp
    end
  end

  def index
    @wisps = Wisp.all
  end
end
