class ChangeNameLengthForRoles < ActiveRecord::Migration
  def self.up
    change_column :roles, :name, :string, :limit => 80
  end

  def self.down
    change_column :roles, :name, :string, :limit => 40
  end
end
