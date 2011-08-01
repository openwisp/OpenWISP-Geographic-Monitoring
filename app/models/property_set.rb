class PropertySet < ActiveRecord::Base
  belongs_to :access_point

  def self.categories(wisp)
    # Categories should be specific for each wisp
    # and dynamic based on which categories are defined
    # on a wisp's access points
    all.map{|set|
      if set.access_point.present? && set.access_point.wisp == wisp
        set.category
      end
    }.compact.uniq.sort
  end
end
