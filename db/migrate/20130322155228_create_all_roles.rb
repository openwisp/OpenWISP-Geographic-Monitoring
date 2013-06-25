class CreateAllRoles < ActiveRecord::Migration
  def self.up
    Wisp.create_all_roles
  end

  def self.down
  end
end
