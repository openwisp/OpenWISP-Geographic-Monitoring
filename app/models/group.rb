class Group < ActiveRecord::Base
  belongs_to :wisp
  has_many :property_set, :dependent => :nullify
  
  validates_presence_of :name
  
  before_destroy :is_default_group?
  
  def toggle_monitor!
    self.monitor = !self.monitor
    self.save
    self.monitor
  end
   
  # DB query
  def self.all_join_wisp(where=nil, params=[])
    if where.nil?: where = '1=1'; end
    self.find_by_sql(["SELECT groups.*, wisps.name AS wisp_name FROM groups
                    LEFT JOIN wisps ON wisps.id = groups.wisp_id
                    WHERE #{where}
                    ORDER BY wisp_id", params])
  end
  
  private

  def is_default_group?
    errors.add(:base, "Cannot delete default group") unless self.id != 1
    errors.blank?
  end
end
