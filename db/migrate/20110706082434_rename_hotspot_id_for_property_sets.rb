class RenameHotspotIdForPropertySets < ActiveRecord::Migration
  def self.up
    rename_column :property_sets, :hotspot_id, :access_point_id
  end

  def self.down
    rename_column :property_sets, :access_point_id, :hotspot_id
  end
end
