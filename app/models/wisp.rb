class Wisp < ActiveRecord::Base
  acts_as_authorization_object

  has_many :hotspots

  delegate :up, :down, :known, :unknown, :to => :hotspots, :prefix => true
end
