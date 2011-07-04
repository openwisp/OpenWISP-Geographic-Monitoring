class AddSiteDescriptionToPropertySet < ActiveRecord::Migration
  def self.up
    add_column :property_sets, :site_description, :string
  end

  def self.down
    remove_column :property_sets, :site_description
  end
end
