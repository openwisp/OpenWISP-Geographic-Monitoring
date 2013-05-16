class AddFavouriteToPropertySet < ActiveRecord::Migration
  def self.up
    add_column :property_sets, :favourite, :boolean
    add_index  :property_sets, :favourite
  end

  def self.down
    remove_column :property_sets, :favourite
  end
end
