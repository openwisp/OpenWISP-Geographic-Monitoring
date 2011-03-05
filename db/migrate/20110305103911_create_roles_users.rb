class CreateRolesUsers < ActiveRecord::Migration
  def self.up
    create_table :roles_users, :id => false, :force => true do |t|
      t.references  :user
      t.references  :role

      t.timestamps
    end
  end

  def self.down
    drop_table :roles_users
  end
end
