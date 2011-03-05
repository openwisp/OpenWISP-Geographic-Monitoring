class AddWispIdToHotspot < ActiveRecord::Migration
  def self.up
    if DATA_FROM[:owm]
      sql = <<-eos
        ALTER VIEW hotspots AS
          SELECT id, name as hostname,
                 lat, lon as lng,
                 address, city,
                 last_configuration_retrieve_ip as mng_ip,
                 notes as description,
                 mac_address as common_name,
                 created_at, updated_at,
                 wisp_id
          FROM owm.access_points
      eos
      execute sql
    elsif DATA_FROM[:table]
      add_column :hotspots, :wisp_id, :integer
    else
      raise "Either DATA_FROM[:table] or DATA_FROM[:owm] must be set to true"
    end
  end

  def self.down
    if DATA_FROM[:owm]
      sql = <<-eos
        ALTER VIEW hotspots AS
          SELECT id, name as hostname,
                 lat, lon as lng,
                 address, city,
                 last_configuration_retrieve_ip as mng_ip,
                 notes as description,
                 mac_address as common_name,
                 created_at, updated_at
          FROM owm.access_points
      eos
      execute sql
    elsif DATA_FROM[:table]
      remove_column :hotspots, :wisp_id
    else
      raise "Either DATA_FROM[:table] or DATA_FROM[:owm] must be set to true"
    end
  end
end
