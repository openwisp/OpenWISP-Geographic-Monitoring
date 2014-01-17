class AddEmailAlertFields < ActiveRecord::Migration
  def self.up
    # add fields to groups
    add_column :groups, :alerts, :boolean, :default => false
    add_column :groups, :alerts_email, :string, :null => true
    add_column :groups, :alerts_threshold_down, :integer, :null => true
    add_column :groups, :alerts_threshold_up, :integer, :null => true
    
    # add fields to access points
    add_column :property_sets, :manager_email, :string, :null => true
    add_column :property_sets, :alerts, :boolean, :null => true, :default => nil
    add_column :property_sets, :alerts_threshold_down, :integer, :null => true
    add_column :property_sets, :alerts_threshold_up, :integer, :null => true
  end

  def self.down
    # remove group fields
    remove_column :groups, :alerts
    remove_column :groups, :alerts_email
    remove_column :groups, :alerts_threshold_down
    remove_column :groups, :alerts_threshold_up
    
    # remove access point fields
    remove_column :property_sets, :manager_email
    remove_column :property_sets, :alerts
    remove_column :property_sets, :alerts_threshold_down
    remove_column :property_sets, :alerts_threshold_up
  end
end
