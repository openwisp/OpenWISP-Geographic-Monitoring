class PropertySet < ActiveRecord::Base
  belongs_to :access_point

  validates :access_point_id, :presence => true
  validates :category, :format => {
      :with => /^\w+\s|\.|\-*\w+$/,
      :allow_blank => true
  }

  def self.categories(wisp)
    # Categories should be specific for each wisp
    # and dynamic based on which categories are defined
    # on a wisp's access points
    wisp.access_points.map{|ap|
        ap.category
    }.compact.uniq.sort
  end
end
