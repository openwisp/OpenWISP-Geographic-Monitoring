class CreateHotspots < ActiveRecord::Migration
  def self.up
    if DATA_FROM[:owm]
      sql = <<-eos
        CREATE VIEW hotspots AS
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
      create_table :hotspots do |t|
        t.string :common_name
        t.string :hostname
        t.string :address
        t.string :city
        t.string :description
        t.float :lat
        t.float :lng
        t.integer :mng_ip

        t.timestamps
      end
    else
      raise "Either DATA_FROM[:table] or DATA_FROM[:owm] must be set to true"
    end
  end

  def self.down
    if DATA_FROM[:owm]
      sql = "DROP VIEW hotspots"
      execute sql
    elsif DATA_FROM[:table]
      drop_table :hotspots
    else
      raise "Either DATA_FROM[:table] or DATA_FROM[:owm] must be set to true"
    end
  end
end

