class AssociatedUserCountHistoriesController < ApplicationController
  before_filter :authenticate_user!, :load_wisp

  access_control do
    default :deny

    actions :show do
      allow :wisps_viewer
      allow :wisp_associated_user_count_histories_viewer, :of => :wisp, :if => :wisp_loaded?
    end
  end

  def show
    @associated_user_count_history = AssociatedUserCountHistory.where(:access_point_id => params[:access_point_id]).older_than(31.days.ago)

    respond_to do |format|
      format.json { render :json => @associated_user_count_history }
    end
  end
end
