class ActivitiesController < ApplicationController
  before_filter :authenticate_user!, :load_wisp

  access_control do
    default :deny

    actions :show do
      allow :wisps_viewer
      allow :wisp_activities_viewer, :of => :wisp, :if => :wisp_loaded?
    end
  end

  def show
    @activity = Activity.where(:access_point_id => params[:access_point_id]).recent

    respond_to do |format|
      format.json { render :json => @activity }
    end
  end
end
