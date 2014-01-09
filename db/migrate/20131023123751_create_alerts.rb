class CreateAlerts < ActiveRecord::Migration
  def self.up
    create_table :alerts do |t|
      t.string :action
      t.boolean :sent, :default => false
      t.integer :access_point_id
      t.timestamps
    end
  end

  def self.down
    drop_table :alerts
  end
end
