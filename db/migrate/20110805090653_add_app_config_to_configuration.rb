class AddAppConfigToConfiguration < ActiveRecord::Migration
  def self.up
    add_column :configurations, :value_format, :string, :default => :string
    add_column :configurations, :description, :string
  end

  def self.down
    remove_column :configurations, :description
    remove_column :configurations, :value_format
  end
end
