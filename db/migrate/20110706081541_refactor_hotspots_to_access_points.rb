class RefactorHotspotsToAccessPoints < ActiveRecord::Migration
  def self.up
    if DATA_FROM[:owm]
      sql = <<-eos
        RENAME TABLE hotspots TO access_points
      eos
      execute sql
    elsif DATA_FROM[:table]
      rename_table :hotspots, :access_points
    else
      raise "Either DATA_FROM[:table] or DATA_FROM[:owm] must be set to true"
    end
  end

  def self.down
    if DATA_FROM[:owm]
      sql = <<-eos
        RENAME TABLE access_points TO hotspots
      eos
      execute sql
    elsif DATA_FROM[:table]
      rename_table :access_points, :hotspots
    else
      raise "Either DATA_FROM[:table] or DATA_FROM[:owm] must be set to true"
    end
  end
end