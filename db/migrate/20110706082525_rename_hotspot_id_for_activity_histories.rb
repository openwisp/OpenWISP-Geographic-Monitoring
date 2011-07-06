class RenameHotspotIdForActivityHistories < ActiveRecord::Migration
  def self.up
    rename_column :activity_histories, :hotspot_id, :access_point_id

    remove_index :activity_histories, :hotspot_id
    add_index :activity_histories, :access_point_id
  end

  def self.down
    rename_column :activity_histories, :access_point_id, :hotspot_id

    remove_index :activity_histories, :access_point_id
    add_index :activity_histories, :hotspot_id
  end
end
