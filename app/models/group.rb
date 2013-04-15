class Group < ActiveRecord::Base
  belongs_to :wisp
  has_many :property_set, :dependent => :nullify
  
  validates_presence_of :name
  
  before_destroy :is_default_group?
  
  def up
    monitor ? self.attributes['up'] : 'N/A'
  end
  
  def down
    monitor ? self.attributes['down'] : 'N/A'
  end
  
  def unknown
    monitor ? self.attributes['unknown'] : 'N/A'
  end
  
  def toggle_monitor!
    self.monitor = !self.monitor
    self.save
    self.monitor
  end
  
  # update group statistics
  def update_counts()
    self.total = PropertySet.where(:group_id => self.id).count
    # up, down and unknown will be updated only if monitoring == true
    if self.monitor
      self.up = PropertySet.where(:group_id => self.id, :reachable => 1).count
      self.down = PropertySet.where(:group_id => self.id, :reachable => 0).count
      self.unknown = PropertySet.where(:group_id => self.id, :reachable => nil).count
    end
    save!
  end
  
  # update statistics for all groups
  def self.update_all_counts()
    self.all.each do |group|
      group.update_counts()
    end
  end
  
  # DB query
  def self.all_join_wisp(where=nil, params=[])
    if where.nil?: where = '1=1'; end
    self.find_by_sql(["SELECT groups.*, wisps.name AS wisp_name FROM groups
                    LEFT JOIN wisps ON wisps.id = groups.wisp_id
                    WHERE #{where}
                    ORDER BY wisp_id"] + params)
  end
  
  # select groups accessible to user
  def self.all_accessible_to(user)
    # if user has role "wisps_viewer" he can see all the groups
    if user.has_role?(:wisps_viewer)
      Group.all_join_wisp
    else
      # if user has any role "wisp_access_points_viewer" of some specific wisp he can see all the groups of those wisps
      where_clause = 'wisp_id IS NULL'
      wisps_id = []
      user.roles_search(:wisp_access_points_viewer).each do |role|
        where_clause << ' OR wisp_id = ?'
        wisps_id << role.authorizable_id
      end
      unless wisps_id.length <= 0
        Group.all_join_wisp(where_clause, wisps_id)
      else
        # if user has neither wisps_viewer nor wisp_access_points_viewer roles he can't see any group
        []
      end
    end
  end
  
  private

  def is_default_group?
    errors.add(:base, I18n.t("Cannot_delete_default_group")) unless self.id != 1
    errors.blank?
  end
end
