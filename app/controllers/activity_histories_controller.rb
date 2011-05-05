class ActivityHistoriesController < ApplicationController
  before_filter :authenticate_user!, :load_wisp

  access_control do
    default :deny

    actions :index, :show do
      allow :wisps_viewer
      allow :wisp_activity_histories_viewer, :of => :wisp, :if => :wisp_loaded?
    end
  end

  def index
    @hotspots = Hotspot.activated(params[:from], params[:to]).of_wisp(@wisp)
  end

  def show
    @activity_history = ActivityHistory.where(:hotspot_id => params[:hotspot_id]).older_than(30.days.ago)

    respond_to do |format|
      format.json { render :json => @activity_history }
    end
  end
end
