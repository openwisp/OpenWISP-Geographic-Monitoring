# This file is part of the OpenWISP Geographic Monitoring
#
# Copyright (C) 2012 OpenWISP.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

class AccessPoint < ActiveRecord::Base
  require 'ipaddr'

  acts_as_authorization_object
  acts_as_mappable :default_units => :kms

  # pagination is handled by kaminari (gem)
  paginates_per CONFIG['default_pagination']
  CLUSTER_ACCESS_POINTS_WITHIN_KM = 2

  belongs_to :wisp
  has_one :property_set, :autosave => true, :dependent => :destroy
  has_many :activities
  has_many :activity_histories
  has_many :associated_user_counts
  has_many :associated_user_count_histories

  delegate :reachable, :to => :property_set, :allow_nil => true
  delegate :category, :category=, :to => :property_set, :allow_nil => true
  delegate :notes, :notes=, :site_description, :site_description=,
           :public, :public=, :favourite, :favourite=,
           :to => :property_set, :allow_nil => true

  def coords
    [lat, lng]
  end

  def site
    base = site_description.present? ? "#{site_description} - " : ""
    base << city
  end

  def ip
    mng_ip.nil? ? nil : IPAddr.new(read_attribute(:mng_ip), Socket::AF_INET).to_s
  end

  def favourite?
    favourite == true
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
      latest.nil? ? '-' : latest.last_time
    end
  end

  def earliest_seen
    unless unknown?
      earliest = activity_histories.first :conditions => ["status > ?", 0], :order => "last_time ASC"
      earliest.nil? ? '-' : earliest.last_time
    end
  end

  def up_average(from, to)
    sprintf "%.1f", activity_histories.observe(activation_date > from ? activation_date : from, to).average_availability
  end

  def down_average(from, to)
    sprintf "%.1f", 100 - activity_histories.observe(activation_date > from ? activation_date : from, to).average_availability
  end

  def associated_users(scope = :all)
    AssociatedUser.active_resource_from(wisp.owmw_url, wisp.owmw_username, wisp.owmw_password)
    AssociatedUser.find(scope, :params => {:access_point => hostname})
  end

  def properties
    property_set.nil? ? build_property_set : property_set
  end

  ##### Static methods #####

  def self.draw_map
    clustered_access_points = []
    already_clustered = []

    find_each do |hs|
      cluster = around(hs.coords)
      cluster -= already_clustered

      clustered_access_points << ( cluster.count > 1 ? Cluster.new(cluster) : cluster.first )

      already_clustered += cluster
    end

    clustered_access_points
  end

  def self.of_wisp(wisp)
    # Skip scope (and let other scopes return results) if wisp is nil
    wisp ? where(:wisp_id => wisp.id) : scoped
  end

  def self.sort_with(attribute, direction)
    case attribute
      when 'status' then
        with_properties.order("`reachable` #{direction}")
      when 'public' then
        with_properties.order("`public` #{direction}")
      when 'site_description' then
        with_properties.order("`site_description` #{direction}")
      else
        order("#{attribute} #{direction}")
    end
  end

  def self.around(coords)
    select("`access_points`.*").geo_scope(:within => CLUSTER_ACCESS_POINTS_WITHIN_KM, :origin => coords)
  end

  def self.on_georss
    with_properties.where(:property_sets => {:public => true})
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

  def self.activated(till=nil)
    where("activation_date <= ?", till)
  end

  def self.all_up(regex=nil)
    AccessPoint.up.hostname_like regex
  end

  def self.all_down(regex=nil)
    AccessPoint.down.hostname_like regex
  end

  def self.all_unknown(regex=nil)
    AccessPoint.unknown.hostname_like regex
  end

  def self.hostname_like(name)
    where("`hostname` LIKE ?", "%#{name}%")
  end

  def self.quicksearch(name)
    where("`hostname` LIKE ? OR `address` LIKE ? OR `city` LIKE ?", *(["%#{name}%"]*3) )
  end

  def self.quickfavourite(condition)
    with_properties.where(:property_sets => {:favourite => condition})
  end

  private

  def self.with_properties
    joins("LEFT JOIN `property_sets` ON `property_sets`.`access_point_id` = `access_points`.`id`")
  end


  def set_reachable_to(boolean)
    property_set.update_attribute(:reachable, boolean) rescue PropertySet.create(:reachable => boolean, :access_point => self)
  end
end
