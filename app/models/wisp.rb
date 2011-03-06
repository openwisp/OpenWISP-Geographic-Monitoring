class Wisp < ActiveRecord::Base
  acts_as_authorization_object

  has_many :hotspots

  def hotspots_up
    hotspots.select{|hs| hs.up?}
  end

  def hotspots_down
    hotspots.select{|hs| hs.down?}
  end

  def hotspots_unknown
    hotspots.select{|hs| hs.unknown?}
  end
end
