class Wisp < ActiveRecord::Base
  acts_as_authorization_object

  has_many :access_points

  delegate :up, :down, :known, :unknown, :to => :access_points, :prefix => true

  def to_param
    "#{name.downcase.gsub(/[^a-z0-9]+/i, '-')}"
  end

  def owmw_enabled?
    Configuration.get(:owmw_enabled) && Configuration.get(:wisps_with_owmw).include?(name)
  end
end
