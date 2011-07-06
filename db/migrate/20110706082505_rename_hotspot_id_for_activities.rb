class RenameHotspotIdForActivities < ActiveRecord::Migration
  def self.up
    rename_column :activities, :hotspot_id, :access_point_id

    remove_index :activities, :hotspot_id
    add_index :activities, :access_point_id
  end

  def self.down
    rename_column :activities, :access_point_id, :hotspot_id

    remove_index :activities, :access_point_id
    add_index :activities, :hotspot_id
  end
end
