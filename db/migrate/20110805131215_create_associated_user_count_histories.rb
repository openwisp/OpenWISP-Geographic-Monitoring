class CreateAssociatedUserCountHistories < ActiveRecord::Migration
  def self.up
    create_table :associated_user_count_histories do |t|
      t.float :count
      t.datetime :start_time
      t.datetime :last_time
      t.integer :access_point_id

      t.timestamps
    end
  end

  def self.down
    drop_table :associated_user_count_histories
  end
end
