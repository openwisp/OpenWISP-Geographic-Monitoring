class Group < ActiveRecord::Base
  belongs_to :wisp
  has_many :property_set, :dependent => :nullify
  
  validates_presence_of :name
  
  # DB query
  def self.all_join_wisp
    self.find_by_sql('SELECT groups.*, wisps.name AS wisp_name FROM groups
                    LEFT JOIN wisps ON wisps.id = groups.wisp_id
                    ORDER BY wisp_id')
  end
end
