class CreatePropertySets < ActiveRecord::Migration
  def self.up
    create_table :property_sets do |t|
      t.boolean :reachable
      t.references :hotspot
    end
  end

  def self.down
    drop_table :property_sets
  end
end
