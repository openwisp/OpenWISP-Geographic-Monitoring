class HotspotsController < ApplicationController
  before_filter :authenticate_user!, :load_wisp

  access_control do
    default :deny

    actions :index, :show do
      allow :wisps_viewer
      allow :wisp_hotspots_viewer, :of => :wisp
    end
  end

  def index
    respond_to do |format|
      format.any(:html, :js) { @hotspots = sort_search_and_paginate }
      format.json { @hotspots = hotspots_with_filter.of_wisp(@wisp).map }
    end
  end

  def show
    @hotspot = Hotspot.find params[:id]
    days_ago = params[:days_ago].to_i

    respond_to do |format|
      format.html
      format.json do
        render :json => @hotspot.activities_older_than(days_ago)
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

  def sort_search_and_paginate
    page = params[:page] || 1
    query = params[:q] || nil
    order = %w{asc desc}.include?(params[:order]) ? params[:order] : 'asc'
    order_column = params[:column].nil? ? nil : params[:column].downcase

    if order_column == I18n.t(:status)
      up = Hotspot.up
      down = Hotspot.down
      unknown = Hotspot.unknown

      if query
        up = up.hostname_like(query)
        down = down.hostname_like(query)
        unknown = unknown.hostname_like(query)
      end

      hotspots = case order
                   when 'asc' then
                     [up, down, unknown].flatten
                   when 'desc' then
                     [down, up, unknown].flatten
                 end

      hotspots.paginate :page => page, :per_page => Hotspot.per_page
    else
      # Find english (main) column name
      i18n_columns = {}

      Hotspot.column_names.each do |col|
        i18n_columns[I18n.t(col, :scope => [:activerecord, :attributes, :hotspot])] = col
      end

      column = i18n_columns.include?(order_column) ? i18n_columns[order_column] : 'hostname'

      unless query.nil?
        conds = {:page => page, :order => column+" "+order, :conditions => ['hostname like ?', "%#{query}%"]}
      else
        conds = {:page => page, :order => column+" "+order}
      end

      Hotspot.paginate conds
    end
  end
end
