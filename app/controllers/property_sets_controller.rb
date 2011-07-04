class PropertySetsController < ApplicationController
  before_filter :authenticate_user!, :load_wisp, :load_hotspot

  access_control do
    default :deny

    actions :update do
      allow :wisps_viewer
      allow :wisp_hotspots_viewer, :of => :wisp, :if => :wisp_loaded?
    end
  end
  
  def update
    if request.xhr?
      @property_set = @hotspot.property_set
      attr, val = params[:property_set].first # For security, restrict only one attribute at a time
      status = @property_set.update_attributes({attr => val}) ? :ok : :unprocessable_entity
      
      render :text => val, :status => status
    else
      render :nothing => true, :status => :not_acceptable
    end
  end

  private

  def load_hotspot
    @hotspot = @wisp.hotspots.find params[:hotspot_id]
  end
end
