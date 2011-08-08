class CreateAssociatedUserCounts < ActiveRecord::Migration
  def self.up
    create_table :associated_user_counts do |t|
      t.integer :count
      t.integer :access_point_id

      t.timestamps
    end
  end

  def self.down
    drop_table :associated_user_counts
  end
end
