class CreateHotspots < ActiveRecord::Migration
  def self.up
    if MIGRATE_USING_VIEWS 
      sql = <<-eos
        CREATE VIEW hotspots AS
          SELECT idhotspot as id, hostname, address, city, description, latitude as lat, longitude as lng, mng_ip FROM #{MIGRATE_DB}.hotspot
      eos
      execute sql
    else
      create_table :hotspots do |t|
        t.string :idhotspot
        t.string :hostname
        t.string :address
        t.string :city
        t.string :description
        t.float :lat
        t.float :lng
        t.integer :mng_ip

        t.timestamps
      end
    end
  end

  def self.down
    if MIGRATE_USING_VIEWS 
      sql = "DROP VIEW hotspots"
      execute sql
    else
      drop_table :hotspots
    end
  end
end
