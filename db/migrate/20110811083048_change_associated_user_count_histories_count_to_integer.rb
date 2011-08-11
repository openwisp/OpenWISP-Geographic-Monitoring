class ChangeAssociatedUserCountHistoriesCountToInteger < ActiveRecord::Migration
  def self.up
    change_column :associated_user_count_histories, :count, :integer
  end

  def self.down
    change_column :associated_user_count_histories, :count, :float
  end
end
