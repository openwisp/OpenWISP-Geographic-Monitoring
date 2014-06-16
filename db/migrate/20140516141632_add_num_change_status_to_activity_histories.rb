class AddNumChangeStatusToActivityHistories < ActiveRecord::Migration
  def self.up
    add_column :activity_histories, :num_change_status, :integer
  end

  def self.down
    remove_column :activity_histories, :num_change_status
  end
end