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
    @from = Date.strptime(params[:from], I18n.t('date.formats.default')) rescue 365.days.ago.to_date
    @to = Date.strptime(params[:to], I18n.t('date.formats.default')) rescue Date.today
    @hotspots = Hotspot.activated(@to).of_wisp(@wisp)

    crumb_for_report
  end

  def show
    @activity_history = ActivityHistory.where(:hotspot_id => params[:hotspot_id]).older_than(30.days.ago)

    respond_to do |format|
      format.json { render :json => @activity_history }
    end
  end

  private

  def crumb_for_report
    add_breadcrumb I18n.t(:Availability_report_for, :wisp => @wisp.name), wisp_availability_report_path(@wisp)
  end
end
