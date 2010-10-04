class HotspotsController < ApplicationController
  before_filter :authenticate_user!

  def index
    @hotspots = sort_search_and_paginate
    
    respond_to do |format|
      format.html do 
        @map = Hotspot.map :show => what_to_show_on_map do |cluster|
          render_to_string :partial => 'info_baloon', :locals => { :hotspot => cluster }
        end
      end
      format.js
    end
  end

  def show
    @hotspot = Hotspot.find params[:id]

    @map = @hotspot.map do |hotspot|
      render_to_string :partial => 'info_baloon', :locals => { :hotspot => hotspot, :single_hotspot => true }
    end
  end
  
  
  
  private
  
  def what_to_show_on_map
    %w{all up down unknown}.include?(params[:filter]) ? params[:filter] : 'all'
  end
  
  def sort_search_and_paginate
    page = params[:page] || 1
    query = params[:q] || nil
    order = %w{asc desc}.include?(params[:order]) ? params[:order] : 'asc'    

    if params[:column] == 'status'
      if query.nil?
        up_hotspots = Hotspot.all_up
        down_hotspots = Hotspot.all_down
        unknown_hotspots = Hotspot.all_unknown
      else
        up_hotspots = Hotspot.all_up query
        down_hotspots = Hotspot.all_down query
        unknown_hotspots = Hotspot.all_unknown query
      end
      
      hotspots = case order
      when 'asc' then
        [up_hotspots, down_hotspots, unknown_hotspots].flatten
      when 'desc' then
        [down_hotspots, up_hotspots, unknown_hotspots].flatten
      end
      
      hotspots.paginate :page => page, :per_page => Hotspot.per_page
    else
      column = Hotspot.column_names.include?(params[:column]) ? params[:column] : 'hostname'
      
      unless query.nil?
        conds = {:page => page, :order => column+" "+order, :conditions => ['hostname like ?', "%#{query}%"]}
      else
        conds = {:page => page, :order => column+" "+order}
      end
      
      Hotspot.paginate conds
    end
  end
end
