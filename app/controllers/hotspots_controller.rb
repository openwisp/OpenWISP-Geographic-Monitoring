class HotspotsController < ApplicationController
  before_filter :authenticate_user!, :load_wisp

  access_control do
    default :deny

    actions :index, :show do
      allow :wisps_viewer
      allow :wisp_hotspots_viewer, :of => :wisp, :if => :wisp_loaded?
    end
  end

  def index
    respond_to do |format|
      format.any(:html, :js) { @hotspots = hotspots_with_sort_seach_and_paginate.of_wisp(@wisp) }
      format.json { @hotspots = hotspots_with_filter.of_wisp(@wisp).draw_map }
    end
  end

  def show
    @hotspot = Hotspot.find params[:id]

    respond_to do |format|
      format.html
      format.json do
        render :json => @hotspot.activity_histories.older_than(30.days.ago)
      end
    end
  end

  private

  def hotspots_with_filter
    case params[:filter]
      when 'up'
        Hotspot.up
      when 'down'
        Hotspot.down
      when 'unknown'
        Hotspot.unknown
      else
        Hotspot
    end
  end

  def hotspots_with_sort_seach_and_paginate
    query = params[:q] || nil
    column = params[:column] ? params[:column].downcase : nil
    direction = %w{asc desc}.include?(params[:order]) ? params[:order] : 'asc'

    hotspots = Hotspot.scoped
    hotspots = hotspots.sort_with(t_column(column), direction) if column
    hotspots = hotspots.hostname_like(query) if query

    hotspots.page params[:page]
  end

  def t_column(column)
    i18n_columns = {}
    i18n_columns[I18n.t(:status, :scope => [:activerecord, :attributes, :hotspot])] = 'status'

    Hotspot.column_names.each do |col|
      i18n_columns[I18n.t(col, :scope => [:activerecord, :attributes, :hotspot])] = col
    end

    i18n_columns.include?(column) ? i18n_columns[column] : 'hostname'
  end
end
