class CreateActivities < ActiveRecord::Migration
  def self.up
    create_table :activities do |t|
      t.integer :status
      t.belongs_to :hotspot

      t.timestamps
    end
    
    add_index :activities, :hotspot_id
    add_index :activities, :created_at
    
  end

  def self.down
    drop_table :activities
  end
end
