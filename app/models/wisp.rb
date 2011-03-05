class Wisp < ActiveRecord::Base
  acts_as_authorization_object

  has_many :hotspots
end
