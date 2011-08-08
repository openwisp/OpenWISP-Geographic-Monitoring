class AssociatedUserCountsController < ApplicationController
  before_filter :authenticate_user!, :load_wisp

  access_control do
    default :deny

    actions :show do
      allow :wisps_viewer
      allow :wisp_associated_user_counts_viewer, :of => :wisp, :if => :wisp_loaded?
    end
  end

  def show
    @associated_user_count = AssociatedUserCount.where(:access_point_id => params[:access_point_id])

    respond_to do |format|
      format.json { render :json => @associated_user_count }
    end
  end
end
