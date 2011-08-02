class RemoveTimestampsFromRolesUsers < ActiveRecord::Migration
  def self.up
    remove_column :roles_users, :created_at
    remove_column :roles_users, :updated_at
  end

  def self.down
    add_column :roles_users, :updated_at, :datetime
    add_column :roles_users, :created_at, :datetime
  end
end
