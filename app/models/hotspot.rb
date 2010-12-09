require "ipaddr"
include Utils

class Hotspot < ActiveRecord::Base
  cattr_reader :per_page
  @@per_page = 10
  
  acts_as_mappable

  has_many :activities
  has_many :activity_histories

  alias_attribute :common_name, :idhotspot

  def coords
    [lat, lng]
  end

  def ip
    mng_ip.nil? ? nil : IPAddr.new(read_attribute(:mng_ip), Socket::AF_INET).to_s
  end

  def up?
    last_state.nil? ? false : last_state
  end

  def down?
    !up? and known?
  end
  
  def unknown?
    ### An unknown hotspot is not considered down!!! ###
    condition1 = self.activities.empty? && self.activity_histories.empty?
    condition2 = (self.activities.count == self.activities.select{|act| act.status == false}.count) && self.activity_histories.empty?
    condition1 || condition2
  end
  
  def known?
    !unknown?
  end

  def status
    if unknown?
      I18n.t(:not_seen)      
    elsif up?
      I18n.t(:up)
    elsif down?
      I18n.t(:down)
    end
  end
  
  def latest_seen  
    unless unknown?
      latest = activity_histories.find(:last, :conditions => ["status > ?", 0], :order => "last_time ASC")
      latest.nil? ? '-' : latest.last_time.to_s(:short)
    else
      '-'
    end
  end
  
  def earliest_seen
    unless unknown?
      earliest = activity_histories.find(:first, :conditions => ["status > ?", 0], :order => "last_time ASC") 
      earliest.nil? ? '-' : earliest.last_time.to_s(:short)
    else
      '-'
    end
  end

  def clients
    clients = OwtsConnector::clients(self.common_name).map{|client| ConnectedClient.new client }
    clients.sort{|client1, client2| client2.last_activity <=> client1.last_activity }
  end

  def marker_image
    hotspot_marker_image
  end

  def activity_graph(opts = {})
    defaults = {
      :type => 'Line', :rotateNames => 1, 
      :showValues => 0, :baseFontSize => 11,
      :chartTopMargin => 30, :yAxisMaxValue => 1,
      :xAxisName => I18n.t(:n_days_ago, :count => 4), 
      :yAxisName => I18n.t(:Avg_availability) 
    }

    graph = FusionCharts::FusionChart.new defaults.merge(opts)
    if self.known?
      histories = self.activity_histories.find :all, :conditions => [ 'start_time >= ?', 3.days.ago ]

      unless histories.select{|history| history.status > 0}.empty?
        histories.each_with_index do |act, idx|
          if idx.even?
            graph.data << { :name => act.start_time.to_date.to_s(:short), :hoverText => act.start_time.to_s(:short), :value => act.status }
          else
            graph.data << { :name => act.start_time.to_date.to_s(:short), :hoverText => act.start_time.to_s(:short), :showName => 0, :value => act.status }
          end
        end
      end
    end

    graph
  end


  def marker(opts = {:cluster => false, :in_cluster => []})
    if opts[:cluster]
      avg_x = avg_y = 0
      opts[:in_cluster].each do |hs|
        avg_x += hs.lat
        avg_y += hs.lng
      end
      
      cluster_info_window = block_given? ? yield(opts[:in_cluster]) : I18n.t(:Cluster)
      
      cluster_coords = [ avg_x/opts[:in_cluster].count, avg_y/opts[:in_cluster].count ]

      GMarker.new(cluster_coords, :title => I18n.t(:Cluster), :info_window => cluster_info_window, :icon => GIcon.new(
        :image=>cluster_marker_image(cluster_average_state(opts[:in_cluster])), 
        :icon_size => GSize.new(32,37), 
        :icon_anchor => GPoint.new(12,38), 
        :info_window_anchor => GPoint.new(20,2))
      )
    else
      single_info_window = block_given? ? yield(self) : hostname
      
      GMarker.new(coords, :title => hostname, :info_window => single_info_window, :icon => GIcon.new(
        :image=>hotspot_marker_image, 
        :icon_size => GSize.new(32,37), 
        :icon_anchor => GPoint.new(12,38), 
        :info_window_anchor => GPoint.new(20,2))
      )
    end
  end

  def map(&block)
    map = GMap.new "map_div"
    map.control_init :map_type => true
    map.static_map_init
    map.center_zoom_init self.coords, 13
    map.declare_init GMarkerManager.new(map, :managed_markers => ManagedMarker.new([marker(&block)], 0, 17)), "mgr"
    map
  end


  ##### Static methods #####

  def self.map(opts, &block)
    x, y, z = get_center_zoom self.all
    map = GMap.new "map_div"
    map.control_init :large_map => true, :map_type => true 
    map.keboard_init
    map.center_zoom_init [x, y], z
    map.declare_init GMarkerManager.new(map, :managed_markers => Hotspot.look_around_to_find_clusters(opts, &block)), "mgr"
    map
  end
  
  def self.all_up(name_regex=nil)
    name_regex.nil? ? Hotspot.all.select{|hs| hs.up?} : Hotspot.all.select{|hs| hs.up? and hs.hostname =~ /#{name_regex}/i}
  end

  def self.all_down(name_regex=nil)
    name_regex.nil? ? Hotspot.all.select{|hs| hs.down?} : Hotspot.all.select{|hs| hs.down? and hs.hostname =~ /#{name_regex}/i}
  end
  
  def self.all_unknown(name_regex=nil)
    name_regex.nil? ? Hotspot.all.select{|hs| hs.unknown?} : Hotspot.all.select{|hs| hs.unknown? and hs.hostname =~ /#{name_regex}/i}
  end


 
  
  protected

  def last_state
    act = self.activities.find(:first, :order => "created_at DESC")
    act.nil? ? nil : act.status
  end




  private
  
  def self.look_around_to_find_clusters(opts = {:show => 'all'}, group_by_distance=2, &block)
    clusters = []

    already_clustered = []
    
    to_remove = case opts[:show]
    when 'up' then
      [self.all_down, self.all_unknown].flatten
    when 'down' then
      [self.all_up, self.all_unknown].flatten
    when 'unknown'
      [self.all_down, self.all_up].flatten
    else
      []
    end
    
    self.all.each do |hs|
      cluster = Hotspot.find :all, :origin => hs.coords, :within => group_by_distance
      cluster = cluster - to_remove
      cluster = cluster - already_clustered
      if cluster.count > 1
        clusters << ManagedMarker.new(cluster.collect{|ap| ap.marker(&block)}, 13, 17)
        clusters << ManagedMarker.new([hs.marker(:cluster => true, :in_cluster => cluster, &block)], 0, 12)
      else
        clusters << ManagedMarker.new(cluster.collect{|ap| ap.marker(&block)}, 0, 17)
      end
      already_clustered += cluster
    end

    clusters
  end

  def hotspot_marker_image
    img = ''
    if unknown?
      img = 'ap_unknown.png'
    elsif up?
      img = 'ap_up.png'
    elsif down?
      img = 'ap_down.png'
    end
    RAILS_SUB_URI+'images/'+img
  end

  def cluster_marker_image(cluster_state)
    img = ''
    if cluster_state == nil
      img = 'cluster_unknown.png'
    elsif cluster_state
      img = 'cluster_up.png'
    else
      img = 'cluster_down.png'
    end
    RAILS_SUB_URI+'images/'+img
  end

  def cluster_average_state(hotspots = [])
    hotspots_up = hotspots_down = hotspots_unknown = 0
    hotspots.each do |hs|
      if hs.unknown?
        hotspots_unknown += 1
      elsif hs.up?
        hotspots_up += 1
      elsif hs.down?
        hotspots_down += 1
      end
    end

    if hotspots_up >= hotspots_down and hotspots_up >= hotspots_unknown
      true
    elsif hotspots_down >= hotspots_up and hotspots_down >= hotspots_unknown
      false
    else
      nil
    end
  end

end
