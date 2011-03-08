class Hotspot < ActiveRecord::Base
  require 'ipaddr'
  extend Addons::Mappable

  acts_as_authorization_object
  acts_as_mappable :default_units => :kms

  paginates_per 10
  CLUSTER_HOTSPOTS_WITHIN_KM = 2

  belongs_to :wisp
  has_one :property_set
  has_many :activities
  has_many :activity_histories

  delegate :reachable, :to => :property_set, :allow_nil => true

  def coords
    [lat, lng]
  end

  def ip
    mng_ip.nil? ? nil : IPAddr.new(read_attribute(:mng_ip), Socket::AF_INET).to_s
  end

  def up?
    reachable == true
  end

  def down?
    reachable == false
  end

  def unknown?
    reachable.nil?
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

  def reachable!
    set_reachable_to true
  end

  def unreachable!
    set_reachable_to false
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

  def self.center
    x, y, z = get_center_zoom self.all
    yield x, y, z if block_given?
    return x, y, z
  end

  def self.draw_map
    clustered_hotspots = []
    already_clustered = []

    find_each do |hs|
      cluster = around(hs.coords)
      cluster -= already_clustered

      clustered_hotspots << ( cluster.count > 1 ? Cluster.new(cluster) : cluster.first )

      already_clustered += cluster
    end

    clustered_hotspots
  end

  def self.of_wisp(wisp)
    where(:wisp_id => wisp.id)
  end

  def self.sort(attribute, direction)
    if attribute == 'status'
      with_properties.order("`reachable` #{direction}")
    else
      order("#{attribute} #{direction}")
    end
  end

  def self.around(coords)
    geo_scope :within => CLUSTER_HOTSPOTS_WITHIN_KM, :origin => coords
  end

  def self.up
    with_properties.where(:property_sets => {:reachable => true})
  end

  def self.down
    with_properties.where(:property_sets => {:reachable => false})
  end

  def self.known
    with_properties.where(:property_sets => {:reachable => [true, false]})
  end

  def self.unknown
    with_properties.where(:property_sets => {:reachable => nil})
  end

  def self.all_up(regex=nil)
    Hotspot.up.hostname_like regex
  end

  def self.all_down(regex=nil)
    Hotspot.down.hostname_like regex
  end

  def self.all_unknown(regex=nil)
    Hotspot.unknown.hostname_like regex
  end

  def self.hostname_like(name)
    where("`hostname` LIKE ?", "%#{name}%")
  end

  private

  def self.with_properties
    joins("LEFT JOIN `property_sets` ON `property_sets`.`hotspot_id` = `hotspots`.`id`")
  end

  def set_reachable_to(boolean)
    property_set.update_attribute(:reachable, boolean) rescue PropertySet.create(:reachable => boolean, :hotspot => self)
  end
end
