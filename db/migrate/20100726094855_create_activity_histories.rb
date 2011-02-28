class CreateActivityHistories < ActiveRecord::Migration
  def self.up
    create_table :activity_histories do |t|
      t.float :status
      t.datetime :start_time
      t.datetime :last_time
      
      t.belongs_to :hotspot

      t.timestamps
    end
    
    add_index :activity_histories, :hotspot_id
    add_index :activity_histories, :start_time
    add_index :activity_histories, :last_time
    
  end

  def self.down
    drop_table :activity_histories
  end
end
