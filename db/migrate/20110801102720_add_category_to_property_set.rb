class AddCategoryToPropertySet < ActiveRecord::Migration
  def self.up
    add_column :property_sets, :category, :string
  end

  def self.down
    remove_column :property_sets, :category
  end
end
