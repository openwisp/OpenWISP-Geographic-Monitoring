class AddNotesToPropertySet < ActiveRecord::Migration
  def self.up
    add_column :property_sets, :notes, :text
  end

  def self.down
    remove_column :property_sets, :notes
  end
end
