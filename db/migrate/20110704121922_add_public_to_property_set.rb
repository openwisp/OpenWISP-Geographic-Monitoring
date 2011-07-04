class AddPublicToPropertySet < ActiveRecord::Migration
  def self.up
    add_column :property_sets, :public, :boolean
  end

  def self.down
    remove_column :property_sets, :public
  end
end
