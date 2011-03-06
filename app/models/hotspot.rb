class Hotspot < ActiveRecord::Base
  require 'ipaddr'
  extend Addons::Mappable

  acts_as_authorization_object

  cattr_reader :per_page
  @@per_page = 10
  
  acts_as_mappable :default_units => :kms

  belongs_to :wisp
  has_many :activities
  has_many :activity_histories

  CLUSTER_HOTSPOTS_WITHIN_KM = 2

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
      -1
    elsif up?
      1
    elsif down?
      0
    end
  end
  
  def latest_seen  
    unless unknown?
      latest = activity_histories.last :conditions => ["status > ?", 0], :order => "last_time ASC"
      latest.nil? ? '-' : latest.last_time.to_s(:short)
    else
      '-'
    end
  end
  
  def earliest_seen
    unless unknown?
      earliest = activity_histories.first :conditions => ["status > ?", 0], :order => "last_time ASC"
      earliest.nil? ? '-' : earliest.last_time.to_s(:short)
    else
      '-'
    end
  end

  def activities_older_than(count)
    if count > 0
      activity_histories.where('start_time >= ?', count.days.ago)
    else
      activity_histories
    end
  end

  def clients
    if OwtsConnector::connected?
      clients = OwtsConnector::clients(self.common_name).map{|client| ConnectedClient.new client }
      clients.delete_if{|client| client.last_activity.to_date <= 1.day.ago.to_date || MacVendor.unknown?(client.mac_address) }
      clients.sort{|client1, client2| client2.last_activity <=> client1.last_activity }
    else
      []
    end
  end


  ##### Static methods #####

  def self.scope_with_wisp(wisp_id)
    default_scope where(:wisp_id => wisp_id)
  end

  def self.around(coords)
    geo_scope :within => CLUSTER_HOTSPOTS_WITHIN_KM, :origin => coords
  end

  def self.center
    x, y, z = get_center_zoom self.all
    yield x, y, z if block_given?
    return x, y, z
  end

  def self.map(opts = {:show => 'all'})
    clustered_hotspots = []
    already_clustered = []
    to_remove = hotspots_to_hide(opts[:show]) 

    self.all.each do |hs|
      cluster = Hotspot.around(hs.coords)
      cluster -= to_remove
      cluster -= already_clustered

      clustered_hotspots << ( cluster.count > 1 ? Cluster.new(cluster) : cluster.first )

      already_clustered += cluster
    end

    clustered_hotspots
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

  def self.up_count
    all_up.count
  end

  def self.down_count
    all_down.count
  end

  def self.unknown_count
    all_unknown.count
  end

  protected

  def last_state
    act = self.activities.order("created_at DESC").first
    act.nil? ? nil : act.status
  end

  private

  def self.hotspots_to_hide(to_show)
    case to_show
    when 'up' then
      [self.all_down, self.all_unknown].flatten
    when 'down' then
      [self.all_up, self.all_unknown].flatten
    when 'unknown'
      [self.all_down, self.all_up].flatten
    else
      []
    end
  end

end
