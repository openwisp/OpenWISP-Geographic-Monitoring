class PropertySetsController < ApplicationController
  before_filter :authenticate_user!, :load_wisp, :load_access_point

  access_control do
    default :deny

    actions :update do
      allow :wisps_viewer
      allow :wisp_access_points_viewer, :of => :wisp, :if => :wisp_loaded?
    end
  end
  
  def update
    if request.xhr?
      @property_set = @access_point.property_set
      attr, val = params[:property_set].first # For security, restrict only one attribute at a time
      status = @property_set.update_attributes({attr => val}) ? :ok : :unprocessable_entity

      # In case a boolean field is updated, translate!
      val = I18n.t(val) if val == 'true' || val == 'false'
      
      render :text => val, :status => status
    else
      render :nothing => true, :status => :not_acceptable
    end
  end

  private

  def load_access_point
    @access_point = @wisp.access_points.find params[:access_point_id]
  end
end
