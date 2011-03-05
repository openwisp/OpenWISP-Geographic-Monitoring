class CreateWisps < ActiveRecord::Migration
  def self.up
    if DATA_FROM[:owm]
      sql = <<-eos
        CREATE VIEW wisps AS
          SELECT id, name, notes, created_at, updated_at
          FROM owm.wisps
      eos
      execute sql
    elsif DATA_FROM[:table]
      create_table :wisps do |t|
        t.string :name
        t.text :notes

        t.timestamps
      end
    else
      raise "Either DATA_FROM[:table] or DATA_FROM[:owm] must be set to true"
    end
  end

  def self.down
    if DATA_FROM[:owm]
      sql = "DROP VIEW wisps"
      execute sql
    elsif DATA_FROM[:table]
      drop_table :wisps
    else
      raise "Either DATA_FROM[:table] or DATA_FROM[:owm] must be set to true"
    end
  end
end
