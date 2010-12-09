class CreateMacVendors < ActiveRecord::Migration
  def self.up
    create_table :mac_vendors do |t|
      t.string :vendor
      t.string :oui

      t.timestamps
    end
  end

  def self.down
    drop_table :mac_vendors
  end
end
